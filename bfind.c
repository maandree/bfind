/* See LICENSE file for copyright and license details. */
#include <sys/stat.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "arg.h"

#define N 500


typedef struct queue {
	char *nodes[N];
	size_t head;
	size_t tail;
	struct queue *next;
	struct queue *prev;
} Queue;

typedef union inode {
	union inode *node[256];
	uint64_t leaf[256 / 64];
} INode;

typedef struct device {
	dev_t dev;
	INode visited;
} Device;


char *argv0;

static Queue queue_head;
static Queue queue_tail;
static Queue queue_pool;
static Device *devices = NULL;
static size_t ndevices = 0;

static int status = 0;
static int xdev = 0;
static int hardlinks = 0;
static int symlinks = 0;
static int visible = 0;


static void
usage(void)
{
	fprintf(stderr, "usage: %s [-0hsvx] [directory]\n", argv0);
	exit(1);
}


static void
enqueue(const char *dir, size_t dir_len, const char *file)
{
	Queue *node;
	size_t file_len;

	node = queue_tail.prev;
	if (!node->prev || node->tail == N) {
		if (queue_pool.next) {
			node = queue_pool.next;
			queue_pool.next = node->next;
		} else {
			node = calloc(1, sizeof(*node));
			if (!node) {
				perror(argv0);
				exit(1);
			}
		}
		node->prev = queue_tail.prev;
		queue_tail.prev->next = node;
		queue_tail.prev = node;
		node->next = &queue_tail;
	}

	file_len = strlen(file);
	node->nodes[node->tail] = malloc(dir_len + file_len + 2);
	if (!node->nodes[node->tail]) {
		perror(argv0);
		exit(1);
	}
	if (dir) {
		memcpy(&node->nodes[node->tail][0], dir, dir_len);
		node->nodes[node->tail][dir_len++] = '/';
	}
	memcpy(&node->nodes[node->tail][dir_len], file, file_len + 1);
	node->tail += 1;
}


static char *
dequeue(void)
{
	Queue *node;
	char *ret;

again:
	node = queue_head.next;
	if (!node->next)
		return NULL;

	if (node->head == node->tail) {
		node->head = node->tail = 0;
		node->prev->next = node->next;
		node->next->prev = node->prev;
		node->prev = NULL;
		node->next = queue_pool.next;
		queue_pool.next = node;
		goto again;
	}

	ret = node->nodes[node->head++];
	if (node->head == node->tail) {
		node->head = node->tail = 0;
		node->prev->next = node->next;
		node->next->prev = node->prev;
		node->prev = NULL;
		node->next = queue_pool.next;
		queue_pool.next = node;
	}

	return ret;
}


static void
enqueue_dir(const char *path)
{
	DIR *dir;
	struct dirent *f;
	size_t path_len = path ? strlen(path) : 0;
	struct stat st;

	if (path && !symlinks) {
		if (lstat(path ? path : ".", &st)) {
			if (errno == ENOENT)
				return;
			fprintf(stderr, "%s: lstat %s: %s\n", argv0, path ? path : ".", strerror(errno));
			status = 1;
			return;
		}
		if (S_ISLNK(st.st_mode))
			return;
	}

	dir = opendir(path ? path : ".");
	if (!dir) {
		if (errno == ENOTDIR || errno == ENOENT || errno == ELOOP)
			return;
		fprintf(stderr, "%s: opendir %s: %s\n", argv0, path ? path : ".", strerror(errno));
		status = 1;
		return;
	}

	errno = 0;
	while ((f = readdir(dir))) {
		if (f->d_name[0] == '.')
			if (visible || !f->d_name[1 + (f->d_name[1] == '.')])
				continue;
		enqueue(path, path_len, f->d_name);
	}

	if (errno) {
		fprintf(stderr, "%s: readdir %s: %s\n", argv0, path ? path : ".", strerror(errno));
		status = 1;
	}

	closedir(dir);
}


static int
visit_inode(Device *dev, ino_t inode)
{
	size_t levels = sizeof(inode);
	INode *tree = &dev->visited;

	while (levels) {
		if (!tree->node[inode & 255])
			goto not_found;
		tree = tree->node[inode & 255];
		inode >>= 8;
		levels--;
	}

	if (tree->leaf[inode / 64] & ((uint64_t)1 << (inode & 63)))
		return 1;

	goto not_visited;

not_found:
	while (levels > 1) {
		tree = tree->node[inode & 255] = calloc(1, levels > 1 ? sizeof(tree->node) : sizeof(tree->leaf));
		if (!tree) {
			fprintf(stderr, "%s: calloc: %s\n", argv0, strerror(errno));
			exit(1);
		}
		inode >>= 8;
		levels--;
	}

not_visited:
	tree->leaf[inode / 64] |= (uint64_t)1 << (inode & 63);
	return 0;
}


int
main(int argc, char *argv[])
{
	char ending = '\n', *path;
	struct stat st;
	dev_t start_dev;
	size_t i;

	ARGBEGIN {
	case '0':
		ending = '\0';
		break;
	case 'h':
		hardlinks = 1;
		break;
	case 's':
		hardlinks = 1;
		symlinks = 1;
		break;
	case 'v':
		visible = 1;
		break;
	case 'x':
		xdev = 1;
		break;
	default:
		usage();
	} ARGEND;

	if (argc > 1)
		usage();

	queue_head.next = &queue_tail;
	queue_tail.prev = &queue_head;

	if (!xdev) {
		if (stat((argc && **argv) ? *argv : ".", &st)) {
			fprintf(stderr, "%s: stat %s: %s\n", argv0, (argc && **argv) ? *argv : ".", strerror(errno));
			return 1;
		}
		start_dev = st.st_dev;
	}

	if (argc && **argv)
		enqueue(NULL, 0, *argv);
	else
		enqueue_dir(NULL);

	while ((path = dequeue())) {
		printf("%s%c", path, ending);
		if (stat(path, &st)) {
			if (errno != ENOENT && errno != ELOOP) {
				fprintf(stderr, "%s: stat %s: %s\n", argv0, path, strerror(errno));
				status = 1;
			}
			continue;
		}
		if (S_ISDIR(st.st_mode)) {
			if (!xdev && st.st_dev != start_dev)
				continue;
			if (hardlinks) {
				for (i = 0; i < ndevices; i++)
					if (devices[i].dev == st.st_dev)
						break;
				if (i == ndevices) {
					devices = realloc(devices, (ndevices + 1) * sizeof(*devices));
					if (!devices) {
						fprintf(stderr, "%s: realloc: %s\n", argv0, strerror(errno));
						status = 1;
					}
					memset(&devices[ndevices], 0, sizeof(*devices));
					devices[ndevices++].dev = st.st_dev;
				}
				if (visit_inode(&devices[i], st.st_ino))
					continue;
			}
			enqueue_dir(path);
		}
		free(path);
	}

	if (fflush(stdout) || ferror(stdout) || fclose(stdout)) {
		fprintf(stderr, "%s: printf: %s\n", argv0, strerror(errno));
		return 1;
	}
	while (queue_pool.next) {
		queue_pool.prev = queue_pool.next;
		queue_pool.next = queue_pool.next->next;
		free(queue_pool.prev);
	}
	return status;
}

#!/usr/bin/env python3
'''
bfind – Minimalitic `find` using breadth first crawling

Copyright © 2013  Mattias Andrée (maandree@member.fsf.org)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
'''

import sys
import os

xdev = False
hardlinks = False
symlinks = False
visible = False
ending = '\n'.encode('utf-8')
dashed = False
path = ''

for arg in sys.argv[1:]:
    if dashed or arg[:1] != '-':  path   = arg
    elif arg == '':               dashed = True
    else:
        if arg == '--xdev'      or (arg[:2] != '--' and 'x' in arg):  xdev      = True
        if arg == '--hardlinks' or (arg[:2] != '--' and 'h' in arg):  hardlinks = True
        if arg == '--symlinks'  or (arg[:2] != '--' and 's' in arg):  symlinks  = True
        if arg == '--visible'   or (arg[:2] != '--' and 'v' in arg):  visible   = True
        if arg == '--print0'    or (arg[:2] != '--' and '0' in arg):  ending    = '\0'.encode('utf-8')

visited_name = set()
visited_id = set()
queue = None
start_dev = os.stat(path if path != '' else '.').st_dev

if path == '':
    queue = os.listdir()
else:
    queue = [path]

while len(queue) > 0:
    path = queue[0]
    queue[:] = queue[1:]
    if visible and (path.startswith('.') or ((os.sep + '.') in path)):
        continue
    if hardlinks:
        stat = os.stat(path)
        stat = (stat.st_dev, stat.st_ino)
        if stat in visited_id:
            continue
        visited_id.add(stat)
    elif symlinks: ## no need if dev/ino is tested
        if os.path.realpath(path) in visited_name:
            continue
        visited_name.add(os.path.realpath(path))
    sys.stdout.buffer.write(path.encode('utf-8'))
    sys.stdout.buffer.write(ending)
    sys.stdout.buffer.flush()
    if not xdev:
        try:
            if os.stat(path).st_dev != start_dev:
                continue
        except:
            pass # link is broken
    if os.path.isdir(path) and (symlinks or not os.path.islink(path)):
        try:
            for subd in os.listdir(path):
                subd = path + os.sep + subd
                queue.append(subd)
        except PermissionError:
            print('Permission denied: %s' % path)


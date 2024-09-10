#!/usr/bin/env python 
import sys
import os
import shutil
import pkgutil
import importlib
import collections

# Name this file (module)
this_module_name = os.path.basename(__file__).rsplit('.')[0]

# Dict for loaders with their modules
loaders = collections.OrderedDict()

# Names's of build-in modules
for module_name in sys.builtin_module_names:

    # Find an information about a module by name
    module = importlib.util.find_spec(module_name)

    # Add a key about a loader in the dict, if not exists yet
    if module.loader not in loaders:
        loaders[module.loader] = []

    # Add a name and a location about imported module in the dict
    loaders[module.loader].append((module.name, module.origin))

# All available non-build-in modules
for module_name in pkgutil.iter_modules():

    # Ignore this module
    if this_module_name == module_name[1]:
        continue

    # Find an information about a module by name
    module = importlib.util.find_spec(module_name[1])

    # Add a key about a loader in the dict, if not exists yet
    loader = type(module.loader)
    if loader not in loaders:
        loaders[loader] = []

    # Add a name and a location about imported module in the dict
    loaders[loader].append((module.name, module.origin))

# Pretty print
# line = '-' * shutil.get_terminal_size().columns
# for loader, modules in loaders.items():
#     print('{0}\n{1}: {2}\n{0}'.format(line, len(modules), loader))
#     for module in modules:
#         print('{0:30} | {1}'.format(module[0], module[1]))



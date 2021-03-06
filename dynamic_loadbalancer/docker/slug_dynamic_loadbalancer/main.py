#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright 2017 Tedezed
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# By: https://github.com/Tedezed
# juanmanuel.torres@aventurabinaria.es

from pykube import HTTPClient, KubeConfig
from time import sleep
from os import system, path
from sys import argv
from deepdiff import DeepDiff

from tools import *

def reload_write_conf():
    template_render = load_singleset_template(patch_exec, list_set)

    file_conf = open('/etc/haproxy/haproxy.cfg', 'w')
    file_conf.write(template_render)
    file_conf.close()
    system('chown haproxy:haproxy /etc/haproxy/haproxy.cfg')
    system('service haproxy reload')

    system('echo [UPDATE] Changes in replicas of %s' % (name_set))

# RUN!
system('echo "Start Slug Load Balancer v.0.0.1"')
# python main.py namespace="default" url_heapster="http://heapster/api/v1/model" autoscaler_count="5" time_query="10"
patch_exec = path.dirname(path.realpath(__file__)) + "/"
#api = HTTPClient(KubeConfig.from_file(patch_exec + "credentials/config"))
api = HTTPClient(KubeConfig.from_service_account())

# Arguments
list_argv = []
argv.remove(argv[0])
for elements in argv:
    variable_entrada = elements.split("=")
    if len(variable_entrada) == 1 or variable_entrada[1] == '':
        raise NameError('[ERROR] Invalid Arguments [python example.py var="text"]')
    list_argv.append(variable_entrada)

dic_argv = argument_to_dic(list_argv)
namespace = dic_argv["namespace"]
# url_heapster = dic_argv["url_heapster"]
time_query = int(dic_argv["time_query"])
name_set = dic_argv["name_set"]
type_balance = dic_argv["type_balance"]
cookie = dic_argv["cookie"].lower()
type_set = dic_argv["type_set"]
try:
    debug = dic_argv["debug"]
except:
    debug = False

if time_query < 5:
    time_query = "5"


# First start
list_set = select_set(name_set, api, namespace, type_balance, cookie, type_set)
system('echo %s' % (list_set))
list_set = select_pod_form_set(api, list_set, namespace)
system('echo %s' % (list_set))

if debug:
    print list_set

reload_write_conf()
old_list_set = list_set

while True:
    list_set = select_set(name_set, api, namespace, type_balance, cookie, type_set)
    list_set = select_pod_form_set(api, list_set, namespace)
    # list_set = percent_cpu_set(list_set)

    ddiff = DeepDiff(list_set, old_list_set)
    if ddiff:
        reload_write_conf()
    else:
        system('echo [INFO] No changes in replicas of %s' % (name_set))

    old_list_set = list_set
    system('echo "Seelp %ss for next query"' % (time_query))
    sleep(time_query)
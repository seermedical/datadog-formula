{% from "datadog/map.jinja" import datadog_install_settings, latest_agent_version, parsed_version with context %}

{%- if grains['os_family'].lower() == 'debian' %}
datadog-apt-https:
  pkg.installed:
    - name: apt-transport-https

datadog-apt-key:
  cmd.run:
    - name: apt-key adv --recv-keys --keyserver 'keyserver.ubuntu.com' D75CEA17048B9ACBF186794B32637D44F14F620E
    - unless: apt-key list | grep 'D75C EA17 048B 9ACB F186  794B 3263 7D44 F14F 620E' || apt-key list | grep 'D75CEA17048B9ACBF186794B32637D44F14F620E'

datadog-apt-key-2024:
  cmd.run:
    - name: apt-key adv --recv-keys --keyserver 'keyserver.ubuntu.com' 5F1E256061D813B125E156E8E6266D4AC0962C7D
    - unless: apt-key list | grep '5F1E 2560 61D8 13B1 25E1  56E8 E626 6D4A C096 2C7D' || apt-key list | grep '5F1E256061D813B125E156E8E6266D4AC0962C7D'

{%- endif %}

datadog-repo:
  pkgrepo.managed:
    - humanname: "Datadog, Inc."
    - refresh: True
    - name: deb https://apt.datadoghq.com/ stable 7
    - keyserver: hkp://keyserver.ubuntu.com:80
    - keyid:
        - A2923DFF56EDA6E76E55E492D3A80E30382E94DE
        - D75CEA17048B9ACBF186794B32637D44F14F620E
        - 5F1E256061D813B125E156E8E6266D4AC0962C7D
    - file: /etc/apt/sources.list.d/datadog.list
    - require:
        - pkg: datadog-apt-https
    - require_in:
        - sls: datadog
    - retry:
        - attempts: 5
        - interval: 1

datadog-pkg:
  pkg.installed:
    - name: datadog-agent
    - refresh: False
    {%- if latest_agent_version %}
    - version: 'latest'
    {%- elif grains['os_family'].lower() == 'debian' %}
    - version: 1:{{ datadog_install_settings.agent_version }}-1
    {%- elif grains['os_family'].lower() == 'redhat' %}
    - version: {{ datadog_install_settings.agent_version }}-1
    {%- endif %}
    - ignore_epoch: True
    - require:
      - pkgrepo: datadog-repo

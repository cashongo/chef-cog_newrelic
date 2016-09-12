# 0.4.0
- monitor postgresql
- mark configuration file template as sensitive
- manage dependencies via peachy_base

# 0.3.2
- loosen version restrictions on cog_php for convenience

# 0.3.1
- fix attribute names
- raise opcache worker level

# 0.3.0
- move to cog_php

# 0.2.16
- set hostname default to fqdn

# 0.2.15
- fix opcache-status log path

# 0.2.14
- fix newrelic plugin log path permissions

# 0.2.13
- fix newrelic path permissions
- bugfix wrong user and mode on opcache monitoring script
- fix install order

# 0.2.12
- disable docker monitor

# 0.2.11
- standardize log format for newrelic-plugin-agent python logger

# 0.2.10
- refactor plugin directories

# 0.2.9
- restrict permissions to newrelic directory
- change log directory opcache

# 0.2.8
- change log directory for opcache to php-fpm related location

# 0.2.7
- update chef-vault to resolve dependency conflict with application cookbook and frontend mysql sync cookbook

# 0.2.4
- add logging for php-fpm opcache-status

# 0.2.3
- add nginx.conf

# 0.2.2
- fix bug in opcach nginx conf

# 0.1.15
- refactor meetme, add python pip from source and python from package

# 0.1.14
- add mongodb config for meetme plugin

# 0.1.12
- add plugins for mysql and gearman

# 0.1.11
- add channelgrabber/newrelic-gearman-plugin

# 0.1.10
- add poise/python dependency for pip lwrp

# 0.1.9
- add plugin_opcache

# 0.1.6
- add php_agent recipe

# 0.1.0
- create initial release of cog_newrelic

name             'cog_newrelic'
maintainer       'Cash on Go Ltd.'
maintainer_email 'andreas.wagner@cashongo.co.uk'
license          'Apache 2.0'
description      'Installs/Configures cog_newrelic'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.2.16'

depends 'chef-vault', '= 1.3.2'
depends 'python',     '= 1.4.6'

name             'cog_newrelic'
maintainer       'Cash on Go Ltd.'
maintainer_email 'andreas.wagner@cashongo.co.uk'
license          'Apache 2.0'
description      'Installs/Configures cog_newrelic'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.4.1'

depends 'python', '1.4.6'
depends 'chef-vault'
depends 'runit'
depends 'cog_php'

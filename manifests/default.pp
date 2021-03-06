# Basic Puppet manifest

Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }


class php5 {

  $phpPackages = [ "php5-cli", "php5-common", "php-apc", "php5-intl", "php5-xdebug", "php5-mysql", "php5-sqlite", "php5-dev" ]
  package { $phpPackages:
    ensure => "installed",
    require => Exec['apt-get update'],
  }

  # as there was an issue in installation order we install that separatly
  package { "php5-cgi":
    ensure => installed,
    require => Exec['apt-get update'],
  }

  file { "/etc/php5/conf.d/custom.ini":
    owner  => root,
    group  => root,
    mode   => 664,
    source => "/vagrant/conf/php/custom.ini",
    require => Package["php5-common"],
  }
  
}

class development {

  $devPackages = [ "curl", "git", "php-pear" ]
  package { $devPackages:
    ensure => "installed",
    require => Exec['apt-get update'],
  }

  exec { 'apt-get update':
    command => "apt-get update",
  }

  exec { 'set pear autodiscover':
    command => 'pear config-set auto_discover 1',
  }

  exec { 'install phpunit':
    command => 'pear install pear.phpunit.de/PHPUnit',
    require => Exec['set pear autodiscover'],
  }
}

class symfony-standard {

  exec { 'git clone symfony standard':
      command => 'git clone https://github.com/symfony/symfony-standard.git /vagrant/www/symfony',
      creates => "/vagrant/www/symfony"
  }

  exec { 'install composer for symfony when needed':
    command => 'curl -s http://getcomposer.org/installer | php -- --install-dir=/vagrant/www/symfony',
    onlyif  => "test -e /vagrant/www/symfony/composer.json",
  }

  exec { 'run composer for symfony when composer is used':
    command => 'php composer.phar install --prefer-source',
    cwd => "/vagrant/www/symfony",
    onlyif  => "test -e /vagrant/www/symfony/composer.json",
  }

  exec { 'run vendor installation from deps when composer is not used':
    command => 'php bin/vendors install',
    cwd => "/vagrant/www/symfony",
    unless  => "test -e /vagrant/www/symfony/composer.json",
  }
}

include php5
include development
include symfony-standard
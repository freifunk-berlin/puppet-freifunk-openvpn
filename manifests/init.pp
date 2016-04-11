class vpn03(
  $inet_dev='eth0',
  $inet_add,
  $inet_min,
  $inet_max,
  $vpn_devs=['tun-tcp', 'tun-udp'],
  $private_networks=['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16', '169.254.0.0/16']
) {

  # add custom repository for freifunk-openvpn (patched openvpn version)
  apt::source { 'sven_ola':
    comment     => 'sven-olas repo for openvpn and other stuff',
    location    => 'http://sven-ola.commando.de/repo',
    release     => 'trusty',
    repos       => 'main',
    pin         => '500',
    key         => 'AF1714D11903D0B2',
    include     => {
      src => false,
      deb => true,
    },
  }
  package { 'freifunk-openvpn':
    ensure => present,
    require => Apt::Source['sven_ola'],
  }

  # ipfilter commands and e.g. NAT configuration
  file { '/etc/rc.local':
    ensure  => present,
    content => template('vpn03/rc.local.erb'),
    mode    => 755,
  }

  # script we use to change the NAT mapping
  file { '/etc/cron.daily/roulette':
    ensure  => absent,
    mode    => 755,
  }

  # add reverseroute table
  file { '/etc/iproute2/rt_tables':
    ensure => present,
    content => template('vpn03/rt_tables.erb'),
    mode    => 755,
  }

  # script we use to learn the back route
  file { '/etc/openvpn/openvpn-learn-address':
    ensure  => present,
    content => template('vpn03/openvpn-learn-address.erb'),
    mode    => 755,
    require => Package['freifunk-openvpn'],
  }

  # tcp and udp openvpn server configuration
  file { '/etc/openvpn/server-tcp.conf':
    ensure  => present,
    content => template('vpn03/server-tcp.conf.erb'),
    require => Package['freifunk-openvpn'],
  }
  file { '/etc/openvpn/server-udp.conf':
    ensure  => present,
    content => template('vpn03/server-udp.conf.erb'),
    require => Package['freifunk-openvpn'],
  }

  sysctl { 'net.ipv4.ip_forward': value => '1' }

  # change conntrack timeouts to prevent droped packages
  sysctl { 'net.netfilter.nf_conntrack_generic_timeout': value => '120' }
  sysctl { 'net.ipv4.netfilter.ip_conntrack_generic_timeout': value => '120' }
  sysctl { 'net.netfilter.nf_conntrack_tcp_timeout_established': value => '120' }
  # double nf_conntrack_max default value
  sysctl { 'net.netfilter.nf_conntrack_max': value => '131072' }
  sysctl { 'net.nf_conntrack_max': value => '131072' }
}

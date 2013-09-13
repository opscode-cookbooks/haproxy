def frontend
  value = {
    http: {
      maxconn: node['haproxy']['frontend_max_connections'],
      option: 'httplog',
      bind: "#{node['haproxy']['incoming_address']}:#{node['haproxy']['incoming_port']}",
      default_backend: 'servers_http' }}
  if node['haproxy']['enable_ssl']
    value.merge!({
      https: {
        maxconn: node['haproxy']['frontend_ssl_max_connections'],
        mode: 'tcp',
        bind: "#{node['haproxy']['ssl_incoming_address']}:#{node['haproxy']['ssl_incoming_port']}",
        default_backend: 'servers_https'}})
  end
  return value
end

def backend
  value = {
    servers_http: {
      server: [ "localhost 127.0.0.1:4000 weight 1 maxconn #{node['haproxy']['member_max_connections']} check",
                "localhost 127.0.0.1:4001 weight 1 maxconn #{node['haproxy']['member_max_connections']} check" ]}}
  if node['haproxy']['enable_ssl']
    value.merge!( {
      servers_https: {
        mode: 'tcp',
        option: ( if node['haproxy']['ssl_httpchk']
                    ['ssl-hello-chk', "httpchk #{node['haproxy']['ssl_httpchk']}"]
                  else
                    ['ssl-hello-chk']
                  end ),
        server: [ "localhost 127.0.0.1:4000 weight 1 maxconn #{node['haproxy']['member_max_connections']} check",
                  "localhost 127.0.0.1:4001 weight 1 maxconn #{node['haproxy']['member_max_connections']} check" ]}})
  end
  return value
end

default['haproxy']['config']['global'] = {
  log: [ '127.0.0.1 local0',
         '127.0.0.1 local1 notice' ],
  maxconn: node['haproxy']['global_max_connections'],
  debug: false,
  quiet: false,
  user: node['haproxy']['user'],
  group: node['haproxy']['group']}

default['haproxy']['config']['defaults'] = {
  log: 'global',
  mode: 'http',
  retries: 3,
  'timeout connect' => '5s',
  'timeout client' => '50s',
  'timeout server' => '50s',
  option: [ 'dontlognull',
            'redispatch' ],
  balance: node['haproxy']['balance_algorithm']}

default['haproxy']['config']['frontend'] = frontend()
default['haproxy']['config']['backend'] = backend()

if node['haproxy']['enable_admin']
  default['haproxy']['config']['listen'] = {
    admin: {
      bind: '127.0.0.1:8081',
      mode: 'http',
      stats: 'uri /' }}
end

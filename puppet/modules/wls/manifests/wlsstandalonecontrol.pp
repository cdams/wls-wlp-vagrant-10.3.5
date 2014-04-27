# == Define: wls::wlscontrol
#
# Weblogic Server control, starts or stops a managed server
#
#  action        = start|stop
#  wlsServerType = admin|managed
#  wlsTarget     = Server|Cluster
#
define wls::wlsstandalonecontrol
( $wlHome         = undef,
  $fullJDKName    = undef,
  $wlsDomain      = undef,
  $wlsDomainPath  = undef,
  $wlsServer      = 'AdminServer',
  $address        = 'localhost',
  $port           = '7001',
  $action         = 'start',
  $wlsUser        = undef,
  $password       = undef,
  $user           = 'oracle',
  $group          = 'dba',
  $downloadDir    = '/install',
  $logOutput      = false,
  $wlsLogDir      = '/data/logs',
) {

   case $operatingsystem {
     CentOS, RedHat, OracleLinux, Ubuntu, Debian, SLES: {
        $execPath         = "/usr/java/${fullJDKName}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:"
        $JAVA_HOME        = "/usr/java/${fullJDKName}"
        $checkCommand     = "/bin/ps -ef | grep -v grep | /bin/grep 'weblogic.Name=${wlsServer}' | /bin/grep ${wlsDomain}"
     }
     Solaris: {
        $execPath         = "/usr/jdk/${fullJDKName}/bin/amd64:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:"
        $JAVA_HOME        = "/usr/jdk/${fullJDKName}"
        $checkCommand     = "/usr/ucb/ps wwxa | grep -v grep | /bin/grep 'weblogic.NodeManager'"
     }
     windows: {
        $execPath         = "C:\\oracle\\${fullJDKName}\\bin;C:\\unxutils\\bin;C:\\unxutils\\usr\\local\\wbin;C:\\Windows\\system32;C:\\Windows"
        $JAVA_HOME        = "c:\\oracle\\${fullJDKName}"
     }
   }

   if $wlsServerType == 'admin' {
     if $action == 'start' {
        $script = 'startWlsServer2.py'
     } elsif $action == 'stop' {
        $script = 'stopWlsServer2.py'
     } else {
        fail("Unknow action")
     }
   } 

   case $operatingsystem {
     CentOS, RedHat, OracleLinux, Ubuntu, Debian, SLES, Solaris: {
     
       if $action == 'start' {
         exec { "start ${wlsServer} ":
          command     => "nohup ${wlsDomainPath}/bin/startWebLogic.sh &",
          unless      => $checkCommand,
          path        => $execPath,
          user        => $user,
          group       => $group,
          logoutput   => $logOutput,
          environment => [  "WLS_REDIRECT_LOG=${wlsLogDir}/start_${wlsServer}.log", 
                            "WLS_STDOUT_LOG=${wlsLogDir}/${wlsDomain}_out.log",
                            "WLS_STDERR_LOG=${wlsLogDir}/${wlsDomain}_err.log",],
          timeout     => 0,
         }
         
          exec { 'sleep':
            command => "sleep 10",
            require => Exec["start ${wlsServer} "],
            path => "/usr/bin:/bin",
            provider => shell,
          }
         
   
       } elsif $action == 'stop' {
         exec { "stop ${wlsServer} ":
          command     => "${wlsDomainPath}/bin/stopWebLogic.sh",
          onlyif      => $checkCommand,
          path        => $execPath,
          user        => $user,
          group       => $group,
          logoutput   => $logOutput,
          timeout     => 0,
         }
       }
     }
     windows: {
        exec { "execwlst ${title}${script}":
          command     => "C:\\Windows\\System32\\cmd.exe /c ${javaCommand} ${path}/${title}${script} ${password}",
          environment => ["CLASSPATH=${wlHome}\\server\\lib\\weblogic.jar",
                          "JAVA_HOME=${JAVA_HOME}"],
          path        => $execPath,
          logoutput   => $logOutput,
          timeout     => 0,
        }
     }
   }
}

########################################################################
# DATE DE CREATION : 03/02/2014
# AUTEUR           : Damien Cuenot
# VERSION          : 1.1.0
# DESCRIPTION      : Installation de Weblogic Portal
########################################################################

define wlp::installwlp (  $version                 = undef,
                          $fullJDKName             = undef,
                          $oracleHome              = undef,
                          $mdwHome                 = undef,
                          $createUser              = true,
                          $user                    = 'oracle',
                          $group                   = 'dba',
                          $downloadDir             = '/install',
                          $remoteFile              = true,
                          $javaParameters          = '', # '-Dspace.detection=false'
                          $puppetDownloadMntPoint  = undef,
                          $osWlsHome               = undef,
                          $osWlpHome               = undef,
                        ){
  
  if($version == '1032') {
    $wlpFile = 'portal1032_generic.jar'
  }
  elsif($version == '1034') {
    $wlpFile = 'portal1034_generic.jar'
  }
  elsif($version == '1035') {
    $wlpFile = 'portal1035_generic.jar'
  }
  elsif($version == '1036') {
    $wlpFile = 'portal1036_generic.jar'
  }
  else {
    $wlpFile = 'portal1035_generic.jar'
  }
  
  
  case $operatingsystem {
     CentOS, RedHat, OracleLinux, Ubuntu, Debian, SLES: {
       $execPath        = "/usr/java/${fullJDKName}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:"
       $path            = $downloadDir
       $beaHome         = $mdwHome

       $oraInventory    = "${oracleHome}/oraInventory"
       $oraInstPath     = "/etc"
       $java_statement  = "java ${javaParameters}"

       Exec { path      => $execPath,
              user      => $user,
              group     => $group,
              logoutput => true,
            }
       File {
              ensure  => present,
              mode    => 0775,
              owner   => $user,
              group   => $group,
              backup  => false,
            }
     }
     Solaris: {

       $execPath        = "/usr/jdk/${fullJDKName}/bin/amd64:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:"
       $path            = $downloadDir
       $beaHome         = $mdwHome

       $oraInventory    = "${oracleHome}/oraInventory"
       $oraInstPath     = "/var/opt"
       $java_statement  = "java -d64 ${javaParameters}"

       Exec { path      => $execPath,
              user      => $user,
              group     => $group,
              logoutput => true,
            }
       File {
              ensure  => present,
              mode    => 0775,
              owner   => $user,
              group   => $group,
              backup  => false,
            }

     }
     windows: {
       $path            = $downloadDir
       $beaHome         = $mdwHome

       $execPath         = "C:\\oracle\\${fullJDKName}\\bin;C:\\unxutils\\bin;C:\\unxutils\\usr\\local\\wbin;C:\\Windows\\system32;C:\\Windows"
       $checkCommand     = "C:\\Windows\\System32\\cmd.exe /c"

       Exec { path      => $execPath,
            }
       File { ensure  => present,
              mode    => 0555,
              backup  => false,
            }
     }
     default: {
       fail("Unrecognized operating system")
     }
  }


  $found = file_exists($osWlpHome)
  notice ("Dossier portal (${osWlpHome}) existe = ${found}")
  
  if($found == false) {

    if $puppetDownloadMntPoint == undef {
      $mountPoint =  "puppet:///modules/wlp/"
    } else {
      $mountPoint = $puppetDownloadMntPoint
    }

    wls::utils::defaultusersfolders{'create wlp home':
      oracleHome      => $oracleHome,
      oraInventory    => $oraInventory,
      createUser      => $createUser,
      user            => $user,
      group           => $group,
      downloadDir     => $path,
    }

    # for performance reasons, download and install or just install it
    if $remoteFile == true {
      file { "wlp.jar ${version}":
         path    => "${path}/${wlpFile}",
         ensure  => file,
         source  => "${mountPoint}/${wlpFile}",
         require => Wls::Utils::Defaultusersfolders['create wlp home'],
         replace => false,
         backup  => false,
      }
    }
    
    # de xml used by the wls installer
    file { "silent_portal.xml ${version}":
      path    => "${path}/silent_portal${version}.xml",
      ensure  => present,
      replace => 'yes',
      content => template("wlp/silent_portal.xml.erb"),
      require => Wls::Utils::Defaultusersfolders['create wlp home'],
    }

    # install weblogic
    case $operatingsystem {
      CentOS, RedHat, OracleLinux, Ubuntu, Debian, SLES, Solaris: {
        if $remoteFile == true {
          exec { "install wlp ${title}":
            command     => "${java_statement} -Xmx1024m -jar ${path}/${wlpFile} -mode=silent -silent_xml=${path}/silent_portal${version}.xml",
            logoutput   => true,
            timeout     => 0,
            require     => [Wls::Utils::Defaultusersfolders['create wlp home'],
                            File ["wlp.jar ${version}"],
                            File ["silent_portal.xml ${version}"],
                           ],
          }
        } else {
          exec { "install wls ${title}":
            command     => "${java_statement} -Xmx1024m -jar ${puppetDownloadMntPoint}/${wlpFile} -mode=silent -silent_xml=${path}/silent_portal${version}.xml",
            logoutput   => true,
            timeout     => 0,
            require     => [Wls::Utils::Defaultusersfolders['create wlp home'],
                            File ["silent_portal.xml ${version}"],
                           ],
          }
        }       
      }
      windows: {
       exec { "install wls ${title}":
         command     => "${checkCommand} /c java -Xmx1024m -jar ${path}/${wlpFile} -mode=silent -silent_xml=${path}/silent_portal${version}.xml",
         timeout     => 0,
         environment => ["JAVA_VENDOR=Sun",
                         "JAVA_HOME=C:\\oracle\\${fullJDKName}"],
         require     => [Wls::Utils::Defaultusersfolders['create wlp home'],File ["wlp.jar ${version}"],File ["silent_portal.xml ${version}"]],
       }
      }
    }
    
  }
  
}

# jrockit::instalrockit

define jrockit::installrockit( 
	$version        =  undef , 
	$x64            =  undef,
	$downloadDir    =  '/install/',
	$puppetMountDir =  undef,
	$installDemos   =  'false',
	$installSource  =  'false',
	$installJre     =  'true',
	$setDefault     =  'true',
	$jreInstallDir  =  '/usr/java',
  $urandomJavaFix =   false,) {

	$fullVersion   =  "jrockit-jdk${version}"
	$installDir    =  "${jreInstallDir}/${fullVersion}"

	notify {"installrockit.pp ${title} ${version}":}

	if $x64 == true {
		$type = 'x64'
	} else {
		$type = 'ia32'
	}

	case $operatingsystem {
		CentOS, RedHat, OracleLinux, Ubuntu, Debian: { 
			$installVersion   = "linux"
			$installExtension = ".bin"
			$user             = "root"
			$group            = "root"
      $path             = '/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:'
		}
		windows: {
			$installVersion   = "windows"
			$installExtension = ".exe"
		}
		default: { 
			fail("Unrecognized operating system") 
		}
	}
 
	$jdkfile =  "jrockit-jdk$version-${installVersion}-${type}${installExtension}"

  Exec {
    path => $path,
    user => $user,
  }
  
	File { 
		replace => false,
	}
  
  exec { "create ${$downloadDir} directory":
    command => "mkdir -p ${$downloadDir}",
    unless  => "test -d ${$downloadDir}",
  }

	# check install folder
	if ! defined(File[$downloadDir]) {
		file { $downloadDir :
			ensure  => directory,
      require => Exec["create ${$downloadDir} directory"],
		}
	}

	# if a mount was not specified then get the install media from the puppet master
    if $puppetMountDir == undef {
	    $mountDir = "puppet:///modules/jrockit/"    	
    } else {
    	$mountDir = $puppetMountDir
    }


	# download jdk to client
	if ! defined(File["${downloadDir}/${jdkfile}"]) {
		file {"${downloadDir}/${jdkfile}":
			path    => "${downloadDir}/${jdkfile}",
			ensure  => present,
			source  => "${mountDir}/${jdkfile}",
			require => File[$downloadDir],
			mode    => 0777,
		} 
	}

	# install on client 
	javaexec {"jdkexec ${title} ${version}": 
		path        => $downloadDir, 
		fullversion => $fullVersion,
		jdkfile     => $jdkfile,
		setDefault  => $setDefault,
		user        => $user,
		group       => $group,
		require     => File["${downloadDir}/${jdkfile}"],
	}
  
  if ($urandomJavaFix == true) {
    exec { "set urandom ${fullVersion}":
      command => "sed -i -e's/securerandom.source=file:\\/dev\\/urandom/securerandom.source=file:\\/dev\\/.\\/urandom/g' ${installDir}/jre/lib/security/java.security",
      unless  => "grep '^securerandom.source=file:/dev/./urandom' ${installDir}/jre/lib/security/java.security",
      require => Javaexec["jdkexec ${title} ${version}"],
    }
  }
}

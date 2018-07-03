@Library('general-pipeline') _

def clone(udid) {
  checkout changelog: true, poll: true, scm: [$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: "$udid/ios-engage-sdk"]], submoduleCfg: [], userRemoteConfigs: [[url: 'git@github.com:emartech/ios-mobile-engage-sdk.git']]]
}

def podi(udid) {
    lock("pod") {
        sh "pod repo update"
        sh "cd $udid/ios-engage-sdk && pod install --verbose"
    }
}

def podiLinti(udid) {
    lock(udid) {
        sh "cd $udid/ios-engage-sdk && pod lib lint --allow-warnings --sources=git@github.com:emartech/pod-private.git,master"
    }
}

def buildAndTest(platform, udid) {
  lock(udid) {
    def uuid = UUID.randomUUID().toString()
    try {
        sh "mkdir /tmp/$uuid"
        retry(3) {
            sh "cd $udid/ios-engage-sdk && scan --scheme MobileEngageTests -d 'platform=$platform,id=$udid' --derived_data_path $uuid -o test_output/unit/"
        }
    } catch(e) {
        currentBuild.result = 'FAILURE'
        throw e
    } finally {
        junit "$udid/ios-engage-sdk/test_output/unit/*.junit"
        archiveArtifacts "$udid/ios-engage-sdk/test_output/unit/*"
    }
  }
}

node('master') {
  withSlack channel:'jenkins', {
      stage('Start'){
          deleteDir()
      }
      stage('Git Clone') {
        parallel iPhone_5S: {
            clone env.IPHONE_5S
         }, iPhone_6S: {
             clone env.IPHONE_6S
        }, iPad_Pro: {
            clone env.IPAD_PRO
        }, iOS_9_3_Simulator: {
            clone env.IOS93SIMULATOR
        }, failFast: false
      }
      stage('Pod install') {
          sh 'eval $(ssh-agent) && ssh-add ~/.ssh/ios-core && ssh-add ~/.ssh/ios-pod-private-repo'
        parallel iPhone_5S: {
            podi env.IPHONE_5S
        // }, iPhone_6S: {
        //     podi env.IPHONE_6S
        }, iPad_Pro: {
            podi env.IPAD_PRO
        }, iOS_9_3_Simulator: {
            podi env.IOS93SIMULATOR
        }, failFast: false
      }
      stage('Pod lint'){
            parallel iPhone_5S: {
                podiLinti env.IPHONE_5S
            // }, iPhone_6S: {
            //     podiLinti env.IPHONE_6S
            }, iPad_Pro: {
                podiLinti env.IPAD_PRO
            }, iOS_9_3_Simulator: {
                podiLinti env.IOS93SIMULATOR
            }, failFast: false
      }
      stage('Build and Test'){
            parallel iPhone_5S: {
                buildAndTest 'iOS', env.IPHONE_5S
            // }, iPhone_6S: {
            //     // echo "Skipped, please trust mac mini when you can open the rack."
            //     buildAndTest 'iOS', env.IPHONE_6S
            }, iPad_Pro: {
                buildAndTest 'iOS', env.IPAD_PRO
            }, iOS_9_3_Simulator: {
                buildAndTest 'iOS Simulator', env.IOS93SIMULATOR
            }, failFast: false
      }
      stage('Deploy to private pod repo'){
          sh "cd $env.IPAD_PRO/ios-engage-sdk && ./deploy-to-private-pod-repo.sh ${env.BUILD_NUMBER}.0.0"
      }
      stage('Finish'){
        echo "That is just pure awesome!"
      }
  }
}

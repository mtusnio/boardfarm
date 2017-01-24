node('boardfarm') {
    stage("Configure") {
        deleteDir()

        sh "sshpass -p 'root' scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            ${env.OTA_DIRECTORY}/ota_update.sh ${env.OTA_DIRECTORY}/ota_verify.sh root@${env.WAN_IP}:~/"
            sh "sshpass -p 'root' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            root@${env.WAN_IP} '/root/ota_update.sh http://${env.WEBSERVER_IP}/openwrt_stable.ubi 192.168.0.2'"
        sh 'sleep 180'

        sh 'echo "ifconfig eth0 up" > /dev/ttyUSB0'
        sh 'echo "ifconfig eth1 up" > /dev/ttyUSB0'
        sh 'sleep 10'
        sh 'echo "ifconfig eth0 192.168.1.1" > /dev/ttyUSB0'
        sh 'echo "ifconfig eth1 192.168.0.2" > /dev/ttyUSB0'

        sh 'echo "iptables -A forwarding_rule -i eth0 -j ACCEPT" > /dev/ttyUSB0'
        sh 'echo "iptables -A forwarding_rule -i eth1 -j ACCEPT" > /dev/ttyUSB0'
        sh 'echo "iptables -A forwarding_rule -o eth0 -j ACCEPT" > /dev/ttyUSB0'
        sh 'echo "iptables -A forwarding_rule -o eth1 -j ACCEPT" > /dev/ttyUSB0'

        sh 'echo "route add default gw 192.168.0.1" > /dev/ttyUSB0'
        sh 'sleep 10'
        sh 'echo "sed -i \'$ a nameserver 8.8.4.4\' /etc/resolv.conf" > /dev/ttyUSB0'
        sh 'sleep 10'

        sh "sshpass -p 'root' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            root@${env.WAN_IP} \"/root/ota_verify.sh 192.168.0.2 && rm /root/ota_*\""
    }

    stage("Run tests") {
        checkout([$class: 'GitSCM',
                userRemoteConfigs: scm.userRemoteConfigs,
                branches: scm.branches,
                doGenerateSubmoduleConfigurations: scm.doGenerateSubmoduleConfigurations,
                submoduleCfg: scm.submoduleCfg,
                browser: scm.browser,
                gitTool: scm.gitTool,
                extensions: scm.extensions + [
                    [$class: 'CleanCheckout'],
                    [$class: 'PruneStaleBranch'],
                ],
        ])
        sh "mkdir -p '${WORKSPACE}/results'"
        sh "export USER='jenkins'; \
            ./bft -x ci40_passed_tests -n ci40_dut \
            -o ./results -c ./boardfarm_config.json -y"

        junit 'results/test_results.xml'
    }
}

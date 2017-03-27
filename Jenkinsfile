def configureDut() {
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
}

properties([
    buildDiscarder(logRotator(numToKeepStr: '10')),
    parameters([
        booleanParam(defaultValue: false,
            description: 'Override distfeeds.conf links',
            name: 'OVERRIDE_PACKAGES'),
        stringParam(defaultValue: '',
            description: 'Works only with OVERRIDE_PACKAGES set to true.\
                          Path to a directory containing the packages folder,\
                          if null defaults to the directory of the image',
            name: "PACKAGES_PATH"),
        stringParam(defaultValue:
            'http://downloads.creatordev.io/openwrt/ci40-v1.1.0/pistachio/marduk/openwrt-v1.1.0-pistachio-marduk-squashfs-factory.ubi',
            description:
            'Either path directly to the image, or path to a Jenkins job from where to get the image',
            name: "IMAGE_PATH"),
        stringParam(defaultValue: 'ci40_passed_tests',
            description: 'Name of testsuite to run on BoardFarm',
            name: "TEST_SUITE"),
    ])
])

node('boardfarm') {
    stage("Configure") {
        deleteDir()

        def image_path = params.IMAGE_PATH.trim()
        def image_name = ""

        if(image_path.endsWith('/')) {
            image_path = image_path.substring(0, image_path.length() - 1)
        }

        if(image_path) {
            /* Match is not serialisable, we cannot save it in a variable to use later */
            if(!(image_path.trim() =~ /(?<=\/)([^\/]+)\.ubi$/)) {
                /* Since it's impossible to use in-built Groovy functions due to sandboxing this little script
                   uses Jenkins XML api to get a list of artifacts and greps between the XML tags for the name of
                   ubi file. */
                image_name = sh (
                    script: "curl -v --silent \
                        '${params.IMAGE_PATH}/api/xml' \
                        2>/dev/null | grep -o -E 'openwrt[^>]+.ubi' | head -n 1",
                    returnStdout: true).trim()
                image_path += "/artifact/bin/pistachio"
            }
            else {
                image_name = (image_path.trim() =~ /(?<=\/)([^\/]+)\.ubi$/)[0][0]
                image_path = image_path.replace("/" + image_name, "")
            }
        }
        else {
            error("Passed null image path")
        }

        def dl_path = "${image_path}/${image_name}"
        sh "wget '${dl_path}' -O ${env.WEBSERVER_PATH}/openwrt.ubi"

        /* Reconfigure the DUT in case it came back from a reboot and no networking
           is available */
        configureDut();

        checkout scm

        def wan_ip = env.WAN_IP
        sh "sshpass -p 'root' scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            scripts/ota_update.sh scripts/ota_verify.sh root@${wan_ip}:~/"
            sh "sshpass -p 'root' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            root@${wan_ip} '/root/ota_update.sh http://${env.WEBSERVER_IP}/openwrt.ubi 192.168.0.2'"
        sh 'sleep 180'

        configureDut();

        if(params.OVERRIDE_PACKAGES) {
            def feeds_path = "${image_path}/packages"

            if(params.PACKAGES_PATH.trim()) {
                feeds_path = params.PACKAGES_PATH.trim()
            }

            if(feeds_path.endsWith('/')) {
                feeds_path = feeds_path.substring(0, feeds_path.length() - 1)
            }

            sh "echo 'sed -E -i \"s;http://.+?/openwrt/.+?/pistachio/marduk/packages;${feeds_path};g\" \
                /etc/opkg/distfeeds.conf' > /dev/ttyUSB0"

            // LEDE will always be in same path within releases/<version>/ or snapshots/
            sh "echo 'sed -E -i \"s;http[s]?.*/(releases/.*/|snapshots/);${feeds_path}/;g\" \
                /etc/opkg/distfeeds.conf' > /dev/ttyUSB0"
        }
        sh "sshpass -p 'root' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            root@${wan_ip} \"/root/ota_verify.sh 192.168.0.2 && rm /root/ota_*\""
    }

    stage("Run tests") {
        sh "sed -i 's/10.40.9.2/${wan_ip}/' boardfarm_config.json"
        sh "mkdir -p '${WORKSPACE}/results'"
        sh "export USER='jenkins'; \
            ./bft -x ${params.TEST_SUITE} -n ci40_dut \
            -o ./results -c ./boardfarm_config.json -y"

        junit 'results/test_results.xml'
    }
}

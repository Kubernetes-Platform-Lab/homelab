default:
	echo "just genconfig;
	echo "just encrypt;
	echo "just decrypt;

generate: genconfig encrypt

genconfig:
	talhelper genconfig ;

encrypt:
	find /dev/shm/clusterconfig  -type f  \( -name "*.yaml" -o -name "talosconfig" -o -name "kubeconfig" \)  -exec sh -c 'sops -e  "$1" > clusterconfig-enc/$(basename "$1")' _ {} \;

decrypt:
    find clusterconfig-enc  -type f  \( -name "*.yaml" -o -name "talosconfig" -o -name "kubeconfig" \)  -exec sh -c 'mkdir -p /dev/shm/clusterconfig;  sops -d "$1" > /dev/shm/clusterconfig/$(basename "$1")' _ {} \;
    ln -s /dev/shm/clusterconfig ./clusterconfig;

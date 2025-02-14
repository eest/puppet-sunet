module Puppet::Parser::Functions
  newfunction(:import_gpg_keys_to_microk8s, :type => :rvalue) do |args|
    configmap = 'kind: ConfigMap
apiVersion: v1
metadata:
  labels:
    app.kubernetes.io/instance: argocd
    app.kubernetes.io/name: argocd-gpg-keys-cm
    app.kubernetes.io/part-of: argocd
  name: argocd-gpg-keys-cm
  namespace: argocd
data:
'

    Dir.glob('/etc/cosmos/keys/*.pub') do |file|
        fingerprint = `gpg --quiet --with-colons --import-options show-only --import --fingerprint < #{file} | grep "^pub:" | awk -F ':' '{print $5}'`
        contents = `cat #{file} | sed 's/^/    /'`
        configmap += '  ' + fingerprint.chop() + ": |-\n"
        configmap += contents
    end
    return `echo "#{configmap}" | microk8s kubectl apply -f -`
  end
end

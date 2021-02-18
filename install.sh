#!/usr/bin/bash

kubectl apply -f files/priv-ds.yaml
sleep 60

kubectl get pods|grep priv| cut -f1 -d\  | while read pod; do
  echo "copy watchdog on $pod"
  kubectl cp files/kubelet-watchdog $pod:/host/opt/bin/kubelet-watchdog
  kubectl exec $pod -- chroot host chmod 755 /opt/bin/kubelet-watchdog

  echo "start watchdog on $pod"
  kubectl cp files/kubelet-watchdog.service $pod:/host/etc/systemd/system/kubelet-watchdog.service
  kubectl exec $pod -- chroot host systemctl daemon-reload
  kubectl exec $pod -- chroot host systemctl start kubelet-watchdog

  echo "start watchdog timer on $pod"
  kubectl cp files/kubelet-watchdog.timer $pod:/host/etc/systemd/system/kubelet-watchdog.timer
  kubectl exec $pod -- chroot host systemctl daemon-reload
  kubectl exec $pod -- chroot host systemctl enable kubelet-watchdog.timer
  kubectl exec $pod -- chroot host systemctl start kubelet-watchdog.timer

done

kubectl delete -f files/priv-ds.yaml

# CorpusOps ppa upgrade workflow
## INSTALL
```sh
sudo apt-get install devscripts debhelper dput python3-paramiko python3-scp python3-paramiko python3-scp
git clone https://github.com/corpusops/nginx.git nginxp/nginx
cd nginxp/nginx
git remote add nginx https://github.com/nginx/nginx.git
git fetch --all
```

## Refresh master
Save current tip to stable branch
```sh
git push origin HEAD:1.XX --force
```

```sh
git fetch --all
git rebase -i nginx/branches/1.XX
mc_packaging/sync_debian.sh
```

## Test build in docker
```sh
docker build -t nginxp:xenial  -f mc_packaging/Dockerfile.xenial .
docker build -t nginxp:focal  -f mc_packaging/Dockerfile.focal .
docker build -t nginxp:bionic  -f mc_packaging/Dockerfile.bionic .
docker build -t nginxp:jammy  -f mc_packaging/Dockerfile.jammy .
docker run --name=nginxp1 --rm -v $PWD:/src_real -ti nginxp:jammy bash
i=$(pwd);apt-get install -f -y libcap2 libmnl0 libxtables12 libcap2-bin  iproute2  $i/nginx-common*.deb /*mod*.deb /*common*.deb /*core*.deb
i=$(pwd);apt-get install -y $i/nginx-common*.deb /*mod*.deb /*common*.deb /*core*.deb
```

## redhat RPMS
- [here](https://github.com/corpusops/nginx/releases/tag/redhat)


## Reapplication des patchs

```sh
git diff --raw --binary --full-index   HEAD..master  -- . ':!auto' ':!.hgtags' ':!conf' ':!contrib' ':!src' ':!misc' ':!docs' >local/packaging.diff
rm -rf mc_packaging/ debian/ auto/cc~* .pc/  auto/cc~* .tito/ .gitignore  nginx.spec auto/cc~*
git apply  --index --reject local/packaging.diff
```

# copy-rockylinux-img2ssd.sh

## 概要

最新のRaspberry Pi用Rocky Linuxのイメージをダウンロードして、SSDにコピーして起動用のRocky LinuxのSSDを作成します。

SSDに作成するパーティションとしては、`boot`を`512MB`、残りすべての領域を`root`として作成します。

Rocky Linuxのイメージでは、`swap`パーティションが作成されていますが、これを作成していません。
必要な場合には、別途で`swap`ファイルを作成して使用するように設定することにします。

SSDに新しく作成したパーティションとファイルシステムに合わせて、SSDの`/boot/cmdline.txt`にある`root`のPARTUUIDを修正しています。

同様にSSDの`/etc/fstab`の`UUID`も修正しています。

この際に、`/etc/fstab`にある`swap`の行をコメントアウトしています。

Rocky Linuxでは、既定値でSELinuxが有効化されているためにコピー直後のSSDから起動して使用できるようにするためにSELinuxを`Disabled`に設定しています。
そのための方法として、SSD内の`/boot/cmdline.txt`ファイルの最後に`selinux=0`のパラメーターを追加しています。

SELinuxを有効化する場合には、`/boot/cmdline.txt`ファイルに追加した`selinux=0`を削除してから再起動します。
この状態で再起動することで再ラベル付けが行われて、SELinuxを有効化することができます。

## 使い方

Raspberry Pi 4で、Rocky LinuxをmSDから起動した状態でコピー先となるSSDを装着します。

現在のスクリプトではSSDが`/dev/sda`として認識されているものとしていますから、もしデバイス名が違う場合にはスクリプトを修正する必要があります。

用意ができれば、スクリプトを実行します。

```bash
$ bash copy-rockylinux-img2ssd.sh
```

概要に記載した処理を実行して、Rocky LinuxのイメージをコピーしたSSDを作成したら終了します。

mSDから起動したRocky Linuxを停止してから、mSDを取り外してSSDだけを装着して状態にして電源を入れます。

起動したら、ユーザー名：`rocky`、パスワード：`rockylinux`でログインします。

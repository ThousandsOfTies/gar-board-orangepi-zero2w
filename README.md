# Orange Pi Zero 2W の基板定義

GAR Productからsubmoduleで取り込む、アプリに依存しない基板データです。

- `board.json`: 基板の識別とOSプロファイルの一覧
- `profiles/armbian-debian13.json`: OS・ABI・コンパイラーの選択、GPIO/SPI資源、起動順、準備方式
- `assets/`: 必要な基板固有のDevice Tree資産（ある場合）

Productは別にアプリとgar-toolsを取り込み、`product.json`でこの基板とプロファイルを選びます。
配線、液晶の型番、ノブ操作の意味、アプリ名、デバウンス値はProductが所有します。
SDK・コンパイラー・ROM本体は格納しません。SDKのインストール場所は個々の開発環境から渡します。

現在のGPIO/SPI一覧は、実機で照合済みの端子に限定した部分的な資源表です。
40ピン全部を検証した一覧ではありません。異なるOSやDevice Treeで使う場合は別プロファイルとして照合してください。

このデータへの分離後のソフトウェア検証と、従来の実機動作確認は区別します。
新しい構成による実機への再導入はまだ行っていません。

## 任意のUSBネットワーク＋コンソール

`assets/usb-link.sh` と `assets/gar-usb-link.service` は、USB0をRNDISとCDC ACMの
複合デバイスにする任意の実機設定です。USB1のHOST機能やGPIO/SPI/I2Cは変更しません。
2026-11-02にArmbian kernel `6.18.57-current-sunxi64` とWindows 11で、
RNDISの自動認識、SSH、外向きHTTPS、ACMコンソールの共存を確認しました。

このserviceはProduct installerから自動適用しません。既存の `g_serial` と同じUDCを
同時使用できないため、シリアルから移行する場合は、設定のバックアップと切断後も動く
復旧処理を用意してから切り替えます。既存のgettyは `ttyGS0` のまま利用しますが、
WindowsのCOM番号は変わります。Windowsのドライバー選択用OS descriptorを含みます。
Linuxの開発用複合デバイスID `1d6b:0104` を使う試作構成です。

配置先はscriptが `/usr/local/sbin/gar-usb-link`、unitが
`/etc/systemd/system/gar-usb-link.service` です。旧 `g_serial` の自動ロードを止め、
libcompositeをロードし、このunitを有効化します。MACとUSB serialはmachine-idから
作り、個体ごとの値をリポジトリへ固定しません。

IPアドレス・DNS・Windows側の通信共有は利用環境側の設定です。この基板資産では
設定しません。ネットワークの実機移行・再起動は接続が切れるため、実行中の管理経路に
依存しないプロセスから行います。再起動後の接続復元は別途確認してください。

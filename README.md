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

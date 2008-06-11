e
= Feature Details
j
= 仕様の詳細
.

e
== Character Encodings

I DO NOT support non-Japanese character encodings until
ruby implements M17N functions. It's too complex for me.

j
== 文字コードの扱いについて

=== 入力

基本的には、パーサへの入力は RFC に沿って正しいエンコードが
なされているものと想定しています。ですが現実にはそうでない
メールも多いので、ある程度の規格外メールは許容しています。
たとえば以下のようなヘッダは TMail のサポート対象です。
(ただし $KCODE が適切にセットされていなければいけません)
--
To: 日本語 <aamine@loveruby.net>
Content-Disposition: attached; filename=日本語.doc
--

また $KCODE=EUC/SJIS の場合は以下のようなヘッダもパース
します。('日本語' は生の iso-2022-jp)
--
To: 日本語 <aamine@loveruby.net>
To: "日本語" <aamine@loveruby.net>
To: Minero Aoki <aamine@loveruby.net> (日本語)
Content-Disposition: attached; filename=日本語.doc
Content-Disposition: attached; filename="日本語.doc"
--
クオートやコメント内に EUC や SJIS、UTF8 を生で入れている
ヘッダはあまりに邪悪すぎるのでサポートしません。

いわゆる半角文字および機種依存文字はとりあえず考慮していません。
が、近くない将来ならば多少はなんとかできるかもしれません。

日本語以外のエンコーディングには、M17N Ruby が安定版として
リリースされるまでは対応しません。

=== デコード出力

TMail の大部分のメソッドは特に断りがない限りデコードした
文字列を返します。文字列の中に日本語文字列が存在する場合は、
$KCODE に従いエンコードを変換して返します。ただしサポート
するのは $KCODE=EUC/SJIS の場合のみで、それ以外 (つまり NONE か UTF8)
のときはエンコーディングは一切変換されません。
Ruby 1.6 以降では $KCODE=NONE がデフォルトなので注意してください。

=== エンコード出力

encoded メソッドを代表としたエンコード出力メソッドはすべて
RFC 的に正しいエンコードを行います (と思います)。出力側で
サポートする文字エンコーディングは iso-2022-jp、MIME エン
コーディングは Base64/B のみです。これは将来に渡って変えません。


e
== Header Comments

TMail discards ALL comments on converting HeaderField objects
into strings, because I cannot preserve position of comments.

j
== コメント

ヘッダにはコメントを含められます。たとえば以下のうち括弧で
くくられた部分がコメントです。
--
To: aamine@loveruby.net (This is comment.)
--
TMail のパーサはコメントをパースしてヘッダオブジェクトの
comments に格納しますが、再文字列化するときはすべて捨てる
ようになっています。なぜかというと、メールヘッダのコメントは
本当にどこにでも置けるようになっているので、パースした後から
ではコメントがどの場所にあったのか判断できないからです。
たとえば以下のようなヘッダはよく見かけます。
--
Received: from mail.loveruby.net (mail.loveruby.net [192.168.1.1])
        by doraemon.edit.ne.jp (8.12.1/8.12.0) with ESMTP id g0CGj4bo035
        for <aamine@mx.edit.ne.jp>; Sun, 13 Jan 2002 01:45:05 +0900 (JST)
--
こういう場合、各コメントをどの要素に所属させるかは人間で
なければ判断できません。ある程度ヒューリスティックにやることは
可能ですが、いったん外れたら完璧に失敗してしまうでしょう。
元のヘッダを再生できるように見せかけておいて時々失敗すると
いうのはあまりに有害ですから、それよりは潔く全部捨てる、
というのがいまのところの結論です。どうせコメントはコメントで
あって本質には関係ないのですから、もうコメントに頼るのは
やめましょう。

特に、アドレスフィールドにおいて本名をコメントに入れたりする
のは最低です。ちゃんと文法的に名前を格納する場所があるのに、
わざわざコメントを使う理由は全くありません。そういうヘッダ
設定をしている人はすぐにメーラか設定かどちらかを変えましょう。

もっとも、大抵の場合にはこれで問題ないのですが、メールの内容を
フィルタリングするような場合は致命傷になりえます。たとえば ML
ドライバでは Subject を加工したりしたいでしょうから、次のような
コードを書きたくなります。
--
mail = TMail::Mail.load(filename)
mail.subject = "[my-list:#{number}] " + mail.subject
mail.write_back
--
しかしこれではコメントが失われてしまいます。消えてもいい
コメントもありますが、Received: のコメントなどは非常に
重要です。

これを避けるには、ひとつの TMail::Mail オブジェクトは常に
情報取得か出力のどちらかだけに限定して使うことです。将来は
もう少しいい方法を考えます。

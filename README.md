# Just Cook

![Just Cook](./assets/logo/logo.png)

レシピを保存し、作る人数に合わせて材料の分量を計算する個人用Webアプリ。
Rails + GraphQL + React + TypeScriptを、機能ごとに理解しながら実装する。

## 技術構成

- バックエンド: Ruby on Rails（APIモード）+ GraphQL-Ruby
- フロントエンド: React + TypeScript
- backend/ と frontend/ を同じリポジトリで管理する予定

現在は初期セットアップ中。Nixの開発環境は用意済みで、Rails・ReactのアプリとDBの起動設定はまだ作成していない。

## 開発環境の方針

- 各ツール・ライブラリは、導入時点の最新安定版を基本とする。互換性やNixでの提供状況によって別のバージョンを選ぶ場合は理由を記録する。
- Nix FlakesでRuby・Node.jsなどの開発ツールを管理し、`nix develop` で開発環境に入る。
- `flake.nix` と `flake.lock` をGit管理し、Nixの入力を固定する。更新は意図的に行う。
- Rubyの依存ライブラリはBundler、フロントエンドの依存ライブラリはpnpmで管理し、それぞれのロックファイルで固定する。
- PostgreSQLはDocker Composeで管理する。RailsとReactはNixの開発環境で実行する。PostgreSQLのバージョンは未選定。

### 確認済みの開発ツール

2026-11-05にユーザーの `x86_64-linux` 環境で確認したバージョン。

| ツール | バージョン |
| --- | --- |
| Ruby | 4.0.9 |
| Node.js | 26.13.0 |
| pnpm | 12.9.0 |
| Bundler | 4.0.20 |

pnpmは、固定したnixpkgsで提供される12.9.0を採用する。公式最新版との差は許容し、Nixで一元管理することを優先する。
Rails・GraphQL-Rubyのバージョンは未選定。

### 開発環境への入り方

Nixを導入し、`nix-command` と `flakes` を有効にしておく。現在の `flake.nix` は `x86_64-linux` 向け。
PostgreSQLの実行には、別途DockerとDocker Composeが必要。

```sh
nix develop
```

環境内でツールを確認する。

```sh
ruby --version
node --version
pnpm --version
bundle --version
```

シェルを開かずに確認する場合は、次を実行する。

```sh
nix develop --command sh -c 'ruby --version; node --version; pnpm --version; bundle --version'
```

PostgreSQLのバージョン選定とCompose設定、Rails・Reactの起動手順は、今後のセットアップで追加する。

## 最初に使える状態

普段作る3品を登録して、2人前から3人前などに変更し、調理中に使えること。

- レシピの一覧・詳細・登録・編集
- レシピ名、基準人数、本文、任意の出典URLを保存
- 本文はMarkdown文字列として保存。最初の入力UIはテキストエリア
- 材料ごとに名前、数量、単位、表示順を保存
- 作る人数を指定すると「元の数量 × 作る人数 ÷ 基準人数」を表示
- 計算によって保存済みの基準人数・数量を書き換えない
- 「少々」「適量」は数量を空にし、別の文字列項目として保存・表示する
- 最初は比例計算の値を表示。材料ごとの自動丸めや味の調整は後から検討する
- 基準人数と作る人数は正の整数。数量は非負の小数を扱う

画像アップロード、URLからの自動取り込み、リッチテキスト編集、認証、公開・共有は初期範囲に含めない。
認証前はローカルで個人利用する。

## データの見取り図（実装前の案）

- Recipe: title, base_servings, body, source_url
- RecipeIngredient: recipe_id, name, quantity（decimal・任意）, unit, quantity_text（任意）, position
- Recipe は複数の RecipeIngredient を持つ
- 材料の数量は数値か「少々」などの文字列のどちらかを指定する

## 実装する順序

1. RailsとReactを起動し、GraphQLの小さなQueryを画面に表示する
2. 名前と本文だけのレシピを1件保存し、詳細画面で取得する
3. 材料を複数登録し、レシピと一緒に取得する
4. 作る人数をQueryに渡し、バックエンドで計算した分量を画面に出す
5. 一覧・編集・入力エラーの表示を整え、3品で実際に使う

各段階で、画面 → GraphQL → Rails → DB の流れを自分の言葉で説明してから進む。
AIは実装前の説明、ヒント、エラーの分析、差分レビューにも使い、一度の変更を小さくする。

## ロゴと履歴

assets/logo/logo.png と assets/logo/logo.svg は既存のものを保持する。
旧Expressバックエンド、Reactの雛形、mobileディレクトリは初期化対象。
以前のコードはGit履歴から参照できる。


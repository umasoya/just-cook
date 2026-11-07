# Just Cook

![Just Cook](./assets/logo/logo.png)

レシピを保存し、作る人数に合わせて材料の分量を計算する個人用Webアプリ。
Rails + GraphQL + React + TypeScriptを、機能ごとに理解しながら実装する。

## 技術構成

- バックエンド: Ruby on Rails（APIモード）+ GraphQL-Ruby
- フロントエンド: React + TypeScript
- backend/ と frontend/ を同じリポジトリで管理する予定

現在は初期セットアップ中。Nixの開発環境、PostgreSQLのCompose設定、`backend/` のRails APIアプリの雛形は用意済み。Railsの依存関係のインストール、direnvからの環境変数の引き継ぎ、Railsからの開発用・テスト用DBの作成、Railsサーバーの起動とブラウザでの `/up` の表示は確認済み。Reactアプリの作成はこれから行う。

## 開発環境の方針

- 各ツール・ライブラリは、導入時点の最新安定版を基本とする。互換性やNixでの提供状況によって別のバージョンを選ぶ場合は理由を記録する。
- Nix FlakesでRuby・Node.jsなどの開発ツールを管理し、`nix develop` で開発環境に入る。
- `flake.nix` と `flake.lock` をGit管理し、Nixの入力を固定する。更新は意図的に行う。
- Rubyの依存ライブラリはBundler、フロントエンドの依存ライブラリはpnpmで管理し、それぞれのロックファイルで固定する。
- PostgreSQLはDocker Composeで管理し、18.6を採用する。RailsとReactはNixの開発環境で実行する。
- PostgreSQLは2026-11-06に[公式のバージョン一覧](https://www.postgresql.org/support/versioning/)で最新安定版が18.6であることを確認した。
- DBのユーザー名・DB名の既定値は `just_cook`。接続先は `127.0.0.1:5432`（PC側のポートは `POSTGRES_PORT` で変更可能）。データは名前付きボリューム `postgres_data` に保存する。

### 確認済みの開発ツール

2026-11-05にユーザーの `x86_64-linux` 環境で確認したバージョン。

| ツール | バージョン |
| --- | --- |
| Ruby | 4.0.9 |
| Node.js | 26.13.0 |
| pnpm | 12.9.0 |
| Bundler | 4.0.20 |

pnpmは、固定したnixpkgsで提供される12.9.0を採用する。公式最新版との差は許容し、Nixで一元管理することを優先する。
Railsは最新安定版の8.1.4.1を採用する（[公式リリース](https://rubyonrails.org/2026/11/4/Rails-8.0.5.2-and-8.1.4.1-have-been-released)）。Rubyの要求バージョンは3.2.0以上で、使用中の4.0.9はその条件を満たす。
GraphQL-Rubyは最新安定版の[2.6.14](https://rubygems.org/gems/graphql/versions/2.6.14)を採用する。Rubyの要求バージョンは2.7.0以上で、[gemの定義](https://github.com/rmosolgo/graphql-ruby/blob/v2.6.14/graphql.gemspec)にRailsのバージョン制約はない。アプリへの導入とRails 8.1.4.1上での動作確認は、GraphQLの実装段階で行う。

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

PostgreSQLをバックグラウンドで起動し、状態を確認する。

```sh
docker compose up -d db
docker compose ps
```

Reactの起動手順は、今後のセットアップで追加する。

### direnvでローカルの環境変数を読み込む

direnvでリポジトリ直下の `.env` を読み込み、RailsとDocker Composeに同じ `POSTGRES_PASSWORD` を渡す。Nixの開発環境には、引き続き `nix develop` で入る。

1. `direnv --version` でインストールを確認する。未導入の場合は普段の環境管理方法でdirenvを導入する。zshでは `~/.zshrc` の末尾に次を設定し、シェルを開き直す。すでに設定済みなら追加は不要。

   ```sh
   eval "$(direnv hook zsh)"
   ```

2. リポジトリ直下の `.gitignore` に次を追加する。既存の `/backend/.env*` は、リポジトリ直下の `.env` を除外しない。

   ```gitignore
   /.env
   /.direnv/
   ```

3. リポジトリ直下に `.env` を作成する。以下の値は実際のローカルDBのパスワードに置き換える。`.env` はコミットしない。

   ```dotenv
   POSTGRES_PASSWORD='ローカルDBのパスワード'
   ```

   既存のDBをComposeの既定値で初期化済みなら、そのパスワードを設定する。既存のデータボリュームがある場合、環境変数を変更してもDB内のパスワードは変更されない。

4. リポジトリ直下に `.envrc` を作成する。こちらには秘密情報を書かず、読み込み処理だけを記載する。

   ```sh
   dotenv .env
   ```

5. リポジトリ直下で読み込みを許可し、パスワードの値を表示せずに確認する。

   ```sh
   direnv allow
   test -n "$POSTGRES_PASSWORD" && echo 'POSTGRES_PASSWORD is set'
   git check-ignore .env
   ```

   `.env` と表示されればGitの除外設定が有効。`.envrc` を編集した場合は、再度 `direnv allow` を実行する。

6. 同じシェルで `nix develop` に入り、リポジトリ直下で `docker compose up -d db` を実行する。`backend/` に移動して実行するRailsにも、環境変数が引き継がれる。`database.yml` は `ENV["POSTGRES_PASSWORD"]` からパスワードを読む。

参考: [direnvのシェル設定](https://direnv.net/docs/hook.html)、[dotenvの公式仕様](https://direnv.net/man/direnv-stdlib.1.html)。direnvからNixの開発環境への環境変数の引き継ぎは、ユーザー環境で確認済み。

### RailsのDB作成と起動確認

direnvで環境変数を読み込み、Nixの開発環境とPostgreSQLを起動した状態で実行する。

```sh
cd backend
bundle install
bin/rails db:create
```

ユーザー環境で `Created database 'backend_development'` と `Created database 'backend_test'` の出力を確認済み。`db:create` はDBそのものを作成する。テーブルの作成・変更はmigrationで行う。

次にRailsサーバーを起動する。

```sh
bin/rails server
```

別のターミナルでヘルスチェックを呼び出す。

```sh
curl -i http://localhost:3000/up
```

HTTP 200が返ることを確認する。ブラウザで http://localhost:3000/up を開いて緑色の画面を確認することもできる。ユーザー環境でRailsサーバーの起動とブラウザでの表示を確認済み。終了はサーバーを起動したターミナルで `Ctrl+C`。`/up` はアプリの起動確認用で、DB接続を確認するエンドポイントではない。

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


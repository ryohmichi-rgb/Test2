# 管理者の指定（ADMIN_USERNAME のユーザーを管理者にする。存在すれば毎回反映）
if (admin_name = ENV["ADMIN_USERNAME"].presence)
  Student.where("lower(username) = ?", admin_name.downcase).update_all(admin: true)
end

# ステータス種別
stat_calc    = StatType.find_or_create_by!(name: "計算力")    { |s| s.description = "四則演算・分数・小数の正確さと速さ"; s.display_order = 1 }
stat_number  = StatType.find_or_create_by!(name: "数的センス") { |s| s.description = "数の性質・規則性・比の理解";         s.display_order = 2 }
stat_shape   = StatType.find_or_create_by!(name: "図形力")    { |s| s.description = "図形の性質・面積・体積の理解";       s.display_order = 3 }
stat_reading = StatType.find_or_create_by!(name: "文章読解力") { |s| s.description = "文章題を式に落とし込む力";           s.display_order = 4 }
stat_logic   = StatType.find_or_create_by!(name: "論理力")    { |s| s.description = "順序立てて考え、式を組み立てる力";   s.display_order = 5 }

# 参考値
[
  { label: "数学の先生",       stat_type: stat_calc,    value: 500 },
  { label: "数学の先生",       stat_type: stat_logic,   value: 400 },
  { label: "数学の先生",       stat_type: stat_number,  value: 350 },
  { label: "高校受験（公立）", stat_type: stat_calc,    value: 300 },
  { label: "高校受験（公立）", stat_type: stat_reading, value: 250 },
  { label: "高校受験（公立）", stat_type: stat_logic,   value: 250 },
  { label: "中学卒業レベル",   stat_type: stat_calc,    value: 200 },
  { label: "中学卒業レベル",   stat_type: stat_number,  value: 150 },
  { label: "中学卒業レベル",   stat_type: stat_reading, value: 150 },

  { label: "難関高校受験",     stat_type: stat_calc,    value: 400 },
  { label: "難関高校受験",     stat_type: stat_logic,   value: 350 },
  { label: "難関高校受験",     stat_type: stat_reading, value: 300 },
  { label: "難関高校受験",     stat_type: stat_number,  value: 300 },

  { label: "エンジニア",       stat_type: stat_logic,   value: 450 },
  { label: "エンジニア",       stat_type: stat_calc,    value: 400 },
  { label: "エンジニア",       stat_type: stat_number,  value: 350 },

  { label: "研究者",           stat_type: stat_logic,   value: 500 },
  { label: "研究者",           stat_type: stat_number,  value: 450 },
  { label: "研究者",           stat_type: stat_reading, value: 400 },
  { label: "研究者",           stat_type: stat_calc,    value: 400 },

  { label: "ゲームクリエイター", stat_type: stat_logic,   value: 350 },
  { label: "ゲームクリエイター", stat_type: stat_shape,   value: 350 },
  { label: "ゲームクリエイター", stat_type: stat_number,  value: 300 }
].each do |ref|
  ReferenceStat.find_or_create_by!(label: ref[:label], stat_type: ref[:stat_type]) do |r|
    r.value = ref[:value]
  end
end

# 教科
math_e = Subject.find_or_create_by!(name: "算数")
math_m = Subject.find_or_create_by!(name: "数学")

# 学年
grade6 = Grade.find_or_create_by!(name: "小学6年生") { |g| g.display_order = 1 }
grade7 = Grade.find_or_create_by!(name: "中学1年生") { |g| g.display_order = 2 }

# === 小学6年生 ===
units_grade6 = [
  {
    title: "分数のかけ算・わり算",
    description: "分数×分数、分数÷分数の計算",
    subject: math_e,
    display_order: 1,
    problems: [
      {
        question: "2/3 × 3/4 を計算しなさい。（分数は a/b の形で答えること）",
        answer: "1/2",
        hint: "分子どうし、分母どうしをかけて、約分しましょう。",
        difficulty: 1,
        problem_type: "fill_in"
      },
      {
        question: "3/5 × 5/6 を計算しなさい。（分数は a/b の形で答えること）",
        answer: "1/2",
        hint: "かける前に約分できるか確認しましょう。",
        difficulty: 2,
        problem_type: "fill_in"
      },
      {
        question: "4/7 ÷ 2/3 を計算しなさい。（分数は a/b の形で答えること）",
        answer: "6/7",
        hint: "わり算はわる数を逆数にしてかけ算に直します。",
        difficulty: 2,
        problem_type: "fill_in"
      }
    ]
  },
  {
    title: "比と比の値",
    description: "比の意味と比の値、等しい比の性質",
    subject: math_e,
    display_order: 2,
    problems: [
      {
        question: "6：9 を最も簡単な整数の比にしなさい。（a:b の形で答えること）",
        answer: "2:3",
        hint: "6と9の最大公約数で割りましょう。",
        difficulty: 1,
        problem_type: "fill_in"
      },
      {
        question: "4：6 = □：9 の □ に当てはまる数を求めなさい。",
        answer: "6",
        hint: "比の値が等しくなるように考えましょう。",
        difficulty: 2,
        problem_type: "fill_in"
      },
      {
        question: "120mLのジュースをAとBが3：2の割合で分けます。Aは何mLになりますか？",
        answer: "72",
        hint: "全体を3+2=5に分けて、Aの分を求めましょう。",
        difficulty: 3,
        problem_type: "fill_in"
      }
    ]
  },
  {
    title: "速さ・時間・距離",
    description: "速さ・時間・距離の関係と計算",
    subject: math_e,
    display_order: 3,
    problems: [
      {
        question: "60kmの道のりを2時間で走ったときの速さは？（km/h）",
        answer: "30",
        hint: "速さ＝距離÷時間",
        difficulty: 1,
        problem_type: "fill_in"
      },
      {
        question: "時速45kmで3時間走ったとき、何km進みますか？",
        answer: "135",
        hint: "距離＝速さ×時間",
        difficulty: 1,
        problem_type: "fill_in"
      },
      {
        question: "分速80mで歩くとき、2.4kmの距離を歩くのに何分かかりますか？",
        answer: "30",
        hint: "2.4km = 2400m。時間＝距離÷速さ",
        difficulty: 3,
        problem_type: "fill_in"
      }
    ]
  },
  {
    title: "文字と式（小6）",
    description: "文字を使った式の表し方と計算",
    subject: math_e,
    display_order: 4,
    problems: [
      {
        question: "1本80円の鉛筆をx本買ったときの代金を式で表しなさい。",
        answer: "80x",
        hint: "（1本の値段）×（本数）",
        difficulty: 1,
        problem_type: "fill_in"
      },
      {
        question: "x = 5 のとき、3x + 2 の値を求めなさい。",
        answer: "17",
        hint: "xに5を代入して計算しましょう。",
        difficulty: 2,
        problem_type: "fill_in"
      }
    ]
  }
]

units_grade6.each do |unit_data|
  problems_data = unit_data.delete(:problems)
  unit = Unit.find_or_create_by!(title: unit_data[:title], grade: grade6) do |u|
    u.subject = unit_data[:subject]
    u.description = unit_data[:description]
    u.display_order = unit_data[:display_order]
  end

  problems_data.each do |pd|
    Problem.find_or_create_by!(question: pd[:question], unit: unit) do |p|
      p.answer = pd[:answer]
      p.hint = pd[:hint]
      p.difficulty = pd[:difficulty]
      p.problem_type = pd[:problem_type]
    end
  end
end

# === 中学1年生 ===
units_grade7 = [
  {
    title: "正の数・負の数",
    description: "正負の数の意味と四則計算",
    subject: math_m,
    display_order: 1,
    problems: [
      {
        question: "（-3）+（-5）を計算しなさい。",
        answer: "-8",
        hint: "負の数どうしの足し算は、絶対値を足して負をつけます。",
        difficulty: 1,
        problem_type: "fill_in"
      },
      {
        question: "（-4）-（-7）を計算しなさい。",
        answer: "3",
        hint: "引き算は、引く数の符号を変えて足し算にします。",
        difficulty: 2,
        problem_type: "fill_in"
      },
      {
        question: "（-3）×（-4）を計算しなさい。",
        answer: "12",
        hint: "負×負＝正",
        difficulty: 2,
        problem_type: "fill_in"
      },
      {
        question: "（-12）÷（+3）を計算しなさい。",
        answer: "-4",
        hint: "負÷正＝負",
        difficulty: 2,
        problem_type: "fill_in"
      },
      {
        question: "次の中で最も大きい数はどれですか？",
        answer: "3",
        hint: "数直線上で右にあるほど大きい数です。",
        difficulty: 1,
        problem_type: "multiple_choice",
        choices: [
          { text: "-5", is_correct: false },
          { text: "-1", is_correct: false },
          { text: "3", is_correct: true },
          { text: "0", is_correct: false }
        ]
      }
    ]
  },
  {
    title: "文字と式",
    description: "文字式の表し方と計算（乗法・除法の省略）",
    subject: math_m,
    display_order: 2,
    problems: [
      {
        question: "a × 3 を文字式の表し方にしなさい。",
        answer: "3a",
        hint: "数は文字の前に書き、×の記号は省略します。",
        difficulty: 1,
        problem_type: "fill_in"
      },
      {
        question: "2x + 3x を計算しなさい。",
        answer: "5x",
        hint: "同類項をまとめましょう。",
        difficulty: 1,
        problem_type: "fill_in"
      },
      {
        question: "3(2x - 4) を展開しなさい。（スペースなし、例: 6x-12）",
        answer: "6x-12",
        hint: "かっこの中の各項に3をかけます。",
        difficulty: 2,
        problem_type: "fill_in"
      },
      {
        question: "x = -2 のとき、4x - 1 の値を求めなさい。",
        answer: "-9",
        hint: "xに-2を代入して計算しましょう。",
        difficulty: 2,
        problem_type: "fill_in"
      }
    ]
  },
  {
    title: "方程式",
    description: "一次方程式の解き方と文章題",
    subject: math_m,
    display_order: 3,
    problems: [
      {
        question: "x + 5 = 12 を解きなさい。",
        answer: "7",
        hint: "両辺から5を引きましょう。",
        difficulty: 1,
        problem_type: "fill_in"
      },
      {
        question: "3x = 18 を解きなさい。",
        answer: "6",
        hint: "両辺を3で割りましょう。",
        difficulty: 1,
        problem_type: "fill_in"
      },
      {
        question: "2x - 3 = 7 を解きなさい。",
        answer: "5",
        hint: "まず両辺に3を足して、次に両辺を2で割りましょう。",
        difficulty: 2,
        problem_type: "fill_in"
      },
      {
        question: "4x + 1 = 2x + 9 を解きなさい。",
        answer: "4",
        hint: "文字を左辺、数を右辺にまとめましょう。",
        difficulty: 3,
        problem_type: "fill_in"
      },
      {
        question: "ある数を3倍して5をひくと16になる。ある数を求めなさい。",
        answer: "7",
        hint: "ある数をxとおいて方程式を立てましょう。3x - 5 = 16",
        difficulty: 3,
        problem_type: "fill_in"
      }
    ]
  },
  {
    title: "比例と反比例",
    description: "比例・反比例の関係とグラフ",
    subject: math_m,
    display_order: 4,
    problems: [
      {
        question: "y = 3x で、x = 4 のときの y の値を求めなさい。",
        answer: "12",
        hint: "xに4を代入しましょう。",
        difficulty: 1,
        problem_type: "fill_in"
      },
      {
        question: "y が x に比例し、x = 2 のとき y = 10 です。比例定数を求めなさい。",
        answer: "5",
        hint: "y = ax の a を求めます。a = y ÷ x",
        difficulty: 2,
        problem_type: "fill_in"
      },
      {
        question: "y = 12/x で、x = 3 のときの y の値を求めなさい。",
        answer: "4",
        hint: "xに3を代入しましょう。",
        difficulty: 2,
        problem_type: "fill_in"
      }
    ]
  }
]

units_grade7.each do |unit_data|
  problems_data = unit_data.delete(:problems)
  unit = Unit.find_or_create_by!(title: unit_data[:title], grade: grade7) do |u|
    u.subject = unit_data[:subject]
    u.description = unit_data[:description]
    u.display_order = unit_data[:display_order]
  end

  problems_data.each do |pd|
    choices_data = pd.delete(:choices) || []
    problem = Problem.find_or_create_by!(question: pd[:question], unit: unit) do |p|
      p.answer = pd[:answer]
      p.hint = pd[:hint]
      p.difficulty = pd[:difficulty]
      p.problem_type = pd[:problem_type]
    end

    choices_data.each do |cd|
      Choice.find_or_create_by!(problem: problem, text: cd[:text]) do |c|
        c.is_correct = cd[:is_correct]
      end
    end
  end
end

# 単元ごとのステータス種別マッピング
{
  "分数のかけ算・わり算" => stat_calc,
  "比と比の値"           => stat_number,
  "速さ・時間・距離"     => stat_reading,
  "文字と式（小6）"      => stat_logic,
  "正の数・負の数"       => stat_calc,
  "文字と式"             => stat_logic,
  "方程式"               => stat_logic,
  "比例と反比例"         => stat_number
}.each do |title, stat_type|
  Unit.where(title: title).update_all(stat_type_id: stat_type.id)
end

# 追加の問題（既存はそのまま、不足分を足す）。title で単元に紐づける。
extra_problems = {
  "分数のかけ算・わり算" => [
    { question: "1/2 × 4/5 を計算しなさい。（分数は a/b の形で答えること）", answer: "2/5", hint: "分子どうし・分母どうしをかけて約分します。", difficulty: 1, problem_type: "fill_in" },
    { question: "5/6 × 3/10 を計算しなさい。（分数は a/b の形で答えること）", answer: "1/4", hint: "先に約分できるか確認しましょう。", difficulty: 2, problem_type: "fill_in" },
    { question: "2/9 ÷ 4/3 を計算しなさい。（分数は a/b の形で答えること）", answer: "1/6", hint: "わる数 4/3 を逆数にしてかけます。", difficulty: 2, problem_type: "fill_in" },
    { question: "3/4 ÷ 6/7 を計算しなさい。（分数は a/b の形で答えること）", answer: "7/8", hint: "6/7 を逆数にしてかけ、約分します。", difficulty: 2, problem_type: "fill_in" },
    { question: "2/3 × 3/4 ÷ 1/2 を計算しなさい。", answer: "1", hint: "左から順に。まず 2/3×3/4=1/2、次に ÷1/2。", difficulty: 3, problem_type: "fill_in" }
  ],
  "比と比の値" => [
    { question: "8 : 12 を最も簡単な整数の比にしなさい。（a:b の形で答えること）", answer: "2:3", hint: "8と12の最大公約数4で割ります。", difficulty: 1, problem_type: "fill_in" },
    { question: "15 : 25 を最も簡単な整数の比にしなさい。（a:b の形で答えること）", answer: "3:5", hint: "5で割りましょう。", difficulty: 1, problem_type: "fill_in" },
    { question: "3 : 4 = 9 : □ の □ に当てはまる数を求めなさい。", answer: "12", hint: "3が9になったので3倍。4も3倍します。", difficulty: 2, problem_type: "fill_in" },
    { question: "10 : 15 = □ : 6 の □ に当てはまる数を求めなさい。", answer: "4", hint: "10:15 を簡単にすると 2:3。それを□:6に合わせます。", difficulty: 2, problem_type: "fill_in" },
    { question: "200円をAとBで 3 : 5 に分けます。Bは何円ですか？", answer: "125", hint: "全体を3+5=8に分け、Bは5つ分。", difficulty: 3, problem_type: "fill_in" }
  ],
  "速さ・時間・距離" => [
    { question: "100kmの道のりを4時間で走ったときの速さは？（km/h）", answer: "25", hint: "速さ＝距離÷時間", difficulty: 1, problem_type: "fill_in" },
    { question: "300mの道のりを分速60mで歩くと何分かかりますか？", answer: "5", hint: "時間＝距離÷速さ", difficulty: 1, problem_type: "fill_in" },
    { question: "時速60kmで2.5時間走ると何km進みますか？", answer: "150", hint: "距離＝速さ×時間", difficulty: 2, problem_type: "fill_in" },
    { question: "秒速5mは分速何mですか？", answer: "300", hint: "1分は60秒。5×60で求めます。", difficulty: 2, problem_type: "fill_in" },
    { question: "時速4kmで3kmの道のりを歩くと何分かかりますか？", answer: "45", hint: "時間＝3÷4＝0.75時間。分に直します。", difficulty: 3, problem_type: "fill_in" }
  ],
  "文字と式（小6）" => [
    { question: "1個120円のりんごを x 個買ったときの代金を式で表しなさい。", answer: "120x", hint: "（1個の値段）×（個数）。×は省略。", difficulty: 1, problem_type: "fill_in" },
    { question: "a円の品物を3個買ったときの代金を式で表しなさい。", answer: "3a", hint: "数は文字の前に書きます。", difficulty: 1, problem_type: "fill_in" },
    { question: "x = 4 のとき、5x の値を求めなさい。", answer: "20", hint: "5×4を計算します。", difficulty: 1, problem_type: "fill_in" },
    { question: "x = 3 のとき、2x + 7 の値を求めなさい。", answer: "13", hint: "2×3に7を足します。", difficulty: 2, problem_type: "fill_in" },
    { question: "1本60円の鉛筆を x 本買って500円を出したときのおつりを式で表しなさい。（スペースなし）", answer: "500-60x", hint: "おつり＝出したお金－代金。", difficulty: 3, problem_type: "fill_in" }
  ],
  "正の数・負の数" => [
    { question: "（-6）+ 9 を計算しなさい。", answer: "3", hint: "符号がちがうときは絶対値の差に大きいほうの符号。", difficulty: 1, problem_type: "fill_in" },
    { question: "7 - 10 を計算しなさい。", answer: "-3", hint: "10のほうが大きいので答えは負になります。", difficulty: 1, problem_type: "fill_in" },
    { question: "（-2）× 5 を計算しなさい。", answer: "-10", hint: "負×正＝負", difficulty: 2, problem_type: "fill_in" },
    { question: "（-20）÷（-4）を計算しなさい。", answer: "5", hint: "負÷負＝正", difficulty: 2, problem_type: "fill_in" }
  ],
  "文字と式" => [
    { question: "5a - 2a を計算しなさい。", answer: "3a", hint: "同類項をまとめます。", difficulty: 1, problem_type: "fill_in" },
    { question: "x ×（-4）を文字式の表し方にしなさい。", answer: "-4x", hint: "符号をつけて数を前に、×は省略。", difficulty: 1, problem_type: "fill_in" },
    { question: "2(3x + 1) を展開しなさい。（スペースなし、例: 6x+2）", answer: "6x+2", hint: "かっこの中の各項に2をかけます。", difficulty: 2, problem_type: "fill_in" },
    { question: "x = -3 のとき、2x + 5 の値を求めなさい。", answer: "-1", hint: "2×(-3)に5を足します。", difficulty: 2, problem_type: "fill_in" }
  ],
  "方程式" => [
    { question: "x - 4 = 9 を解きなさい。", answer: "13", hint: "両辺に4を足します。", difficulty: 1, problem_type: "fill_in" },
    { question: "5x = 35 を解きなさい。", answer: "7", hint: "両辺を5で割ります。", difficulty: 1, problem_type: "fill_in" },
    { question: "3x + 2 = 14 を解きなさい。", answer: "4", hint: "まず2を移項、次に3で割ります。", difficulty: 2, problem_type: "fill_in" },
    { question: "2x + 3 = x + 8 を解きなさい。", answer: "5", hint: "xを左、数を右に移項します。", difficulty: 2, problem_type: "fill_in" }
  ],
  "比例と反比例" => [
    { question: "y = 5x で、x = 3 のときの y の値を求めなさい。", answer: "15", hint: "xに3を代入します。", difficulty: 1, problem_type: "fill_in" },
    { question: "y = 24/x で、x = 6 のときの y の値を求めなさい。", answer: "4", hint: "24を6で割ります。", difficulty: 1, problem_type: "fill_in" },
    { question: "y = -2x で、x = 4 のときの y の値を求めなさい。", answer: "-8", hint: "-2×4を計算します。", difficulty: 2, problem_type: "fill_in" },
    { question: "y が x に比例し、x = 3 のとき y = 12 です。比例定数を求めなさい。", answer: "4", hint: "a = y ÷ x で求めます。", difficulty: 2, problem_type: "fill_in" }
  ]
}

extra_problems.each do |title, probs|
  unit = Unit.find_by(title: title)
  next unless unit

  probs.each do |pd|
    Problem.find_or_create_by!(question: pd[:question], unit: unit) do |p|
      p.answer = pd[:answer]
      p.hint = pd[:hint]
      p.difficulty = pd[:difficulty]
      p.problem_type = pd[:problem_type]
    end
  end
end

# 単元ごとの教材（解説）Markdown。既存単元にも反映されるよう update で入れる。
lessons = {
  "分数のかけ算・わり算" => <<~MD,
    ## 分数のかけ算・わり算

    ケーキやジュースを「何等分の何こ分」と考えるときに使うのが分数です。かけ算・わり算は、ルールさえ覚えれば整数の計算よりもむしろ単純です。

    ### かけ算のやり方
    **分子どうし・分母どうしをかける**だけです。

    - 2/3 × 3/4 = (2×3)/(3×4) = 6/12
    - 最後に**約分**して 6/12 = 1/2

    かける前に約分できるときは、先に約分すると数が小さくなって計算が楽です。

    ### わり算のやり方
    **わる数をひっくり返して（逆数にして）かける**だけです。

    - 4/7 ÷ 2/3 = 4/7 × 3/2 = 12/14 = 6/7

    ### れいだい
    3/5 × 5/6 を計算しよう。
    1. 分子どうし・分母どうしをかける → (3×5)/(5×6) = 15/30
    2. 約分する → 15/30 = **1/2**

    （先に約分してもOK：5どうしを消して 3/6 = 1/2）

    ### よくあるまちがい
    - ❌ わり算で、分母どうし・分子どうしをそのまま割る
    - ⭕ わり算は「ひっくり返してかける」に直す
    - ❌ 約分をわすれて 6/12 のままにする
    - ⭕ 答えは必ず「これ以上約分できないか」を確認する

    ### ポイント
    - 分数×分数＝分子×分子 / 分母×分母
    - 分数÷分数＝わる数を逆数にしてかけ算に直す
    - 答えは必ず約分できないか確認する
  MD

  "比と比の値" => <<~MD,
    ## 比と比の値

    「牛乳とコーヒーを 3 : 2 でまぜる」のように、**2つの量の割合**を表すのが比です。`a : b` と書き、料理や地図、拡大・縮小など身のまわりでよく使います。

    ### 比を簡単にする
    両方を**同じ数で割る**と、比は簡単になります（割合＝比の値は変わりません）。

    - 6 : 9 → 6と9を3で割って **2 : 3**

    ### 等しい比
    `4 : 6 = □ : 9` は、**何倍になったか**を考えます。

    - 6 が 9 になるには 1.5倍。だから 4 も 1.5倍して **6**

    ### 全体を分ける
    「3 : 2 に分ける」なら、全体を **3 + 2 = 5** に分けて考えます。

    ### れいだい
    120mL のジュースを A と B で 3 : 2 に分けよう。A は何mL？
    1. 全体を 3 + 2 = 5 に分ける
    2. 1つ分は 120 ÷ 5 = 24mL
    3. A は3つ分なので 24 × 3 = **72mL**

    ### よくあるまちがい
    - ❌ 「3 : 2 に分ける」で、全体を3で割ってしまう
    - ⭕ まず「3 + 2 = 5」で全体をいくつに分けるか出す
    - ❌ 比を簡単にするとき、片方だけ割る
    - ⭕ 両方を同じ数で割る

    ### ポイント
    - 比は同じ数で割っても等しい
    - 分けるときは「全体をいくつに分けるか」をまず出す
  MD

  "速さ・時間・距離" => <<~MD,
    ## 速さ・時間・距離

    電車やランニング、車の運転…「どのくらいの速さで、どのくらいの時間で、どこまで進むか」を計算できると、生活のいろいろな場面で役立ちます。

    3つの関係は、次の1つの式から全部わかります。

    **距離 ＝ 速さ × 時間**

    ここから、
    - 速さ ＝ 距離 ÷ 時間
    - 時間 ＝ 距離 ÷ 速さ

    ### れいだい
    分速80m で 2.4km を歩くと何分かかる？
    1. 単位をそろえる：2.4km = **2400m**
    2. 時間 ＝ 距離 ÷ 速さ ＝ 2400 ÷ 80 = **30分**

    ### よくあるまちがい
    - ❌ km と m など、単位がちがうまま計算する
    - ⭕ まず単位をそろえてから計算する
    - ❌ どれを割ればいいか毎回まよう
    - ⭕ 「距離＝速さ×時間」を1つ覚えれば、あとは逆算で出る

    ### ポイント
    - 「み・は・じ」（道のり・速さ・時間）の関係を1つ覚える
    - まず単位をそろえる
  MD

  "文字と式（小6）" => <<~MD,
    ## 文字と式（小6）

    まだわからない数や、あとで変わる数を**文字**（x など）で表すと、いろいろな場面を1つの式で書けます。買い物の代金の計算などで便利です。

    ### 式で表す
    - 1本80円の鉛筆を x 本 → 代金は **80 × x = 80x**
    - ×の記号は**省略**し、数を文字の前に書きます。

    ### 代入する
    文字に数を当てはめて計算することを**代入**といいます。

    ### れいだい
    x = 5 のとき、3x + 2 の値を求めよう。
    1. x を 5 に置きかえる → 3×5 + 2
    2. 計算する → 15 + 2 = **17**

    ### よくあるまちがい
    - ❌ 80x を「80 たす x」だと思う
    - ⭕ 80x は「80 かける x」（×を省略しただけ）
    - ❌ 3x に x=5 を入れて「35」と書く
    - ⭕ 3x は 3×x なので 3×5 = 15

    ### ポイント
    - 「×」は省略。80×x は 80x
    - 代入は「文字を数に置きかえる」だけ
  MD

  "正の数・負の数" => <<~MD,
    ## 正の数・負の数

    気温の「−3℃」や地下の「−2階」のように、0より小さい数＝**負の数**は生活の中にもあります。数直線で考えると分かりやすいです。

    ### 大小
    数直線で**右にあるほど大きい**。だから −5 < −1 < 0 < 3。

    ### たし算・ひき算
    - 同じ符号どうしのたし算：絶対値を足して符号をつける → (−3)+(−5) = **−8**
    - ひき算は「引く数の符号を変えてたし算」→ (−4)−(−7) = (−4)+7 = **3**

    ### かけ算・わり算
    符号のルールはシンプルです。
    - 同じ符号どうし → **＋**：(−3)×(−4) = 12
    - ちがう符号どうし → **−**：(−12)÷(+3) = −4

    ### れいだい
    (−4) − (−7) を計算しよう。
    1. 「−(−7)」は符号を変えて「+7」
    2. (−4) + 7 = **3**

    ### よくあるまちがい
    - ❌ (−4)−(−7) を −4−7 = −11 としてしまう
    - ⭕ 引く数の符号を変えて (−4)+7 = 3
    - ❌ 負×負を負にしてしまう
    - ⭕ 負×負＝**正**

    ### ポイント
    - 負×負＝正、負×正＝負
    - ひき算は符号を変えてたし算に直す
  MD

  "文字と式" => <<~MD,
    ## 文字と式（中1）

    小6で習った文字式を、中学ではもっと整理して計算します。式を「きれいにまとめる」練習です。

    ### 書き方のルール
    - ×は省略、数は文字の前：a × 3 → **3a**
    - 同じ文字どうしはまとめられる（**同類項**）：2x + 3x = **5x**

    ### かっこを外す（分配法則）
    かっこの前の数を、**中の全部の項に**かけます。

    - 3(2x − 4) = 3×2x − 3×4 = **6x − 12**

    ### れいだい
    2(3x + 1) を展開しよう。
    1. かっこの前の2を 3x にかける → 6x
    2. 2を +1 にもかける → +2
    3. 合わせて **6x + 2**

    ### よくあるまちがい
    - ❌ 3(2x−4) で、最初の項だけにかけて 6x−4
    - ⭕ **中の全部の項**にかける → 6x−12
    - ❌ 2x + 3 を 5x とまとめる（文字と数はまとまらない）
    - ⭕ まとめられるのは同じ文字どうし（2x と 3x など）

    ### ポイント
    - 同類項（同じ文字）はまとめる
    - かっこは1つ1つの項にかけて外す
  MD

  "方程式" => <<~MD,
    ## 方程式

    「ある数を3倍して5ひくと16。ある数は？」——こんな“逆算パズル”を、式できちんと解くのが方程式です。x を使えば、むずかしい文章題も手順どおりに解けます。

    ### 基本の考え方
    **両辺に同じことをしても、＝は成り立つ**。これを使って x だけを残します。

    - x + 5 = 12 → 両辺から5を引く → x = **7**
    - 3x = 18 → 両辺を3で割る → x = **6**

    ### 移項
    文字を左、数を右に集めます。反対側に移すと**符号が変わる**（＝移項）。

    ### れいだい
    2x − 3 = 7 を解こう。
    1. −3 を右に移項（符号が変わって +3）→ 2x = 7 + 3 = 10
    2. 両辺を2で割る → x = **5**

    ### よくあるまちがい
    - ❌ 移項したのに符号を変えない（2x = 7 − 3 とする）
    - ⭕ 移項すると符号が変わる → 2x = 7 + 3
    - ❌ 3x = 18 を x = 18 − 3 とする
    - ⭕ かけ算は「割る」でほどく → x = 18 ÷ 3

    ### ポイント
    - 両辺に同じ操作をする
    - 移項したら符号が変わる
  MD

  "比例と反比例" => <<~MD,
    ## 比例と反比例

    「時間が2倍になると進む距離も2倍」——このように、片方が増えるともう片方も決まった割合で変わる関係を式にします。

    ### 比例：y = ax
    x が2倍・3倍になると、y も2倍・3倍になる関係。a を**比例定数**といいます。

    - y = 3x で x = 4 → y = 3×4 = **12**

    ### 反比例：y = a/x
    x が2倍になると y は 1/2 になる関係（**x × y が一定**）。

    - y = 12/x で x = 3 → y = 12 ÷ 3 = **4**

    ### れいだい
    y は x に比例し、x = 2 のとき y = 10。比例定数 a を求めよう。
    1. 比例は y = ax
    2. a = y ÷ x = 10 ÷ 2 = **5**（式は y = 5x）

    ### よくあるまちがい
    - ❌ 比例定数を y × x で求める
    - ⭕ 比例は a = y ÷ x
    - ❌ 反比例なのに y = ax で考える
    - ⭕ 反比例は y = a/x（x×y が一定）

    ### ポイント
    - 比例は y = ax（わり算で a が出る）
    - 反比例は y = a/x（x×y が一定）
  MD
}

lessons.each do |title, body|
  Unit.where(title: title).update_all(lesson_body: body)
end

puts "Seed完了: #{Grade.count}学年, #{Unit.count}単元, #{Problem.count}問題, #{StatType.count}ステータス種別, 教材#{lessons.size}件"

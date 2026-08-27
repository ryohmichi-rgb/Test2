# 管理者の指定（ADMIN_USERNAME のユーザーを管理者にする。存在すれば毎回反映）
# 解説（solution）を、まだ入っていない問題にだけ入れる。
# find_or_create_by! のブロックは新規作成のときしか走らないので、これが無いと
# あとから足した解説が既存の問題に反映されない。
# 「空のときだけ」にしているのは、管理画面で直した解説を seed が上書きしないため。
def fill_solution(problem, solution)
  return if solution.blank? || problem.solution.present?
  problem.update!(solution: solution)
end


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
        question: '$\frac{2}{3} \times \frac{3}{4}$ を計算しなさい。（分数は a/b の形で答えること）',
        answer: "1/2",
        hint: "分子どうし、分母どうしをかけて、約分しましょう。",
        difficulty: 1,
        problem_type: "fill_in", solution: '分数のかけ算は、分母どうし・分子どうしをかけます。$\frac{2 \times 3}{3 \times 4} = \frac{6}{12}$ となり、約分して $\frac{1}{2}$ です。先に約分してから計算してもかまいません。'
      },
      {
        question: '$\frac{3}{5} \times \frac{5}{6}$ を計算しなさい。（分数は a/b の形で答えること）',
        answer: "1/2",
        hint: "かける前に約分できるか確認しましょう。",
        difficulty: 2,
        problem_type: "fill_in", solution: '分母どうし・分子どうしをかけて $\frac{15}{30}$。約分すると $\frac{1}{2}$ です。$5$ どうしを先に約分すると計算が楽になります。'
      },
      {
        question: '$\frac{4}{7} \div \frac{2}{3}$ を計算しなさい。（分数は a/b の形で答えること）',
        answer: "6/7",
        hint: "わり算はわる数を逆数にしてかけ算に直します。",
        difficulty: 2,
        problem_type: "fill_in", solution: '分数のわり算は、$\div$ を $\times$ に変えて後ろの分数をひっくり返します。$\frac{4}{7} \times \frac{3}{2} = \frac{12}{14}$ となり、約分して $\frac{6}{7}$ です。'
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
        problem_type: "fill_in", solution: '比は、両方を同じ数でわって小さくします。$6$ と $9$ の最大公約数は $3$ なので、両方を $3$ でわって $2:3$ です。'
      },
      {
        question: "4：6 = □：9 の □ に当てはまる数を求めなさい。",
        answer: "6",
        hint: "比の値が等しくなるように考えましょう。",
        difficulty: 2,
        problem_type: "fill_in", solution: 'まず $4:6$ を簡単にすると $2:3$ です。$9$ は $3$ の $3$ 倍なので、$□$ も $2$ の $3$ 倍で $6$ になります。'
      },
      {
        question: "120mLのジュースをAとBが3：2の割合で分けます。Aは何mLになりますか？（単位はつけず数字だけで答えること）",
        answer: "72",
        hint: "全体を3+2=5に分けて、Aの分を求めましょう。",
        difficulty: 3,
        problem_type: "fill_in", solution: '全体を $3+2=5$ とみます。Aは全体の $\frac{3}{5}$ にあたるので、$120 \times \frac{3}{5} = 72$ です。'
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
        question: "60kmの道のりを2時間で走ったときの速さは、時速何kmですか？（単位はつけず数字だけで答えること）",
        answer: "30",
        hint: "速さ＝距離÷時間",
        difficulty: 1,
        problem_type: "fill_in", solution: '速さ $=$ 道のり $\div$ 時間 です。$60 \div 2 = 30$ なので、時速 $30$ km になります。'
      },
      {
        question: "時速45kmで3時間走ったとき、何km進みますか？（単位はつけず数字だけで答えること）",
        answer: "135",
        hint: "距離＝速さ×時間",
        difficulty: 1,
        problem_type: "fill_in", solution: '道のり $=$ 速さ $\times$ 時間 です。$45 \times 3 = 135$ なので $135$ km 進みます。'
      },
      {
        question: "分速80mで歩くとき、2.4kmの距離を歩くのに何分かかりますか？（単位はつけず数字だけで答えること）",
        answer: "30",
        hint: "2.4km = 2400m。時間＝距離÷速さ",
        difficulty: 3,
        problem_type: "fill_in", solution: 'まず単位をそろえます。$2.4$ km $= 2400$ m です。時間 $=$ 道のり $\div$ 速さ なので $2400 \div 80 = 30$ 分になります。'
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
        question: '1本80円の鉛筆を $x$ 本買ったときの代金を式で表しなさい。',
        answer: "80x",
        hint: "（1本の値段）×（本数）",
        difficulty: 1,
        problem_type: "fill_in", solution: '代金 $=$ 1本の値段 $\times$ 本数 なので $80 \times x$ です。文字式では $\times$ を省いて $80x$ と書きます。'
      },
      {
        question: '$x = 5$ のとき、$3x + 2$ の値を求めなさい。',
        answer: "17",
        hint: '$x$ に5を代入して計算しましょう。',
        difficulty: 2,
        problem_type: "fill_in", solution: '$x$ のところに $5$ を入れます。$3 \times 5 + 2 = 15 + 2 = 17$ です。かけ算を先に計算します。'
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
    problem_row = Problem.find_or_create_by!(question: pd[:question], unit: unit) do |p|
      p.answer = pd[:answer]
      p.hint = pd[:hint]
      p.difficulty = pd[:difficulty]
      p.problem_type = pd[:problem_type]
      p.solution = pd[:solution]
    end
    # find_or_create_by! のブロックは新規作成のときしか走らない。
    # 解説をあとから足したので、すでにある問題にも入れる（空のときだけ＝管理画面の編集は残す）。
    fill_solution(problem_row, pd[:solution])
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
        question: '$(-3) + (-5)$ を計算しなさい。',
        answer: "-8",
        hint: "負の数どうしの足し算は、絶対値を足して負をつけます。",
        difficulty: 1,
        problem_type: "fill_in", solution: '同じ符号どうしのたし算は、絶対値をたして符号はそのままにします。$3 + 5 = 8$ で、どちらもマイナスなので $-8$ です。'
      },
      {
        question: '$(-4) - (-7)$ を計算しなさい。',
        answer: "3",
        hint: "引き算は、引く数の符号を変えて足し算にします。",
        difficulty: 2,
        problem_type: "fill_in", solution: 'ひき算は、ひく数の符号を変えてたし算に直します。$(-4) + (+7)$ となるので $3$ です。'
      },
      {
        question: '$(-3) \times (-4)$ を計算しなさい。',
        answer: "12",
        hint: "負×負＝正",
        difficulty: 2,
        problem_type: "fill_in", solution: 'マイナス $\times$ マイナスはプラスになります。$3 \times 4 = 12$ なので答えは $12$ です。'
      },
      {
        question: '$(-12) \div (+3)$ を計算しなさい。',
        answer: "-4",
        hint: "負÷正＝負",
        difficulty: 2,
        problem_type: "fill_in", solution: '符号が違うわり算の答えはマイナスになります。$12 \div 3 = 4$ なので $-4$ です。'
      },
      {
        question: "次の中で最も大きい数はどれですか？",
        answer: "3",
        hint: "数直線上で右にあるほど大きい数です。",
        difficulty: 1,
        problem_type: "multiple_choice", solution: '数直線では右にあるほど大きい数です。マイナスの数は $0$ より小さいので、この中では $3$ が最も大きくなります。',
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
        question: '$a \times 3$ を文字式の表し方にしなさい。',
        answer: "3a",
        hint: "数は文字の前に書き、×の記号は省略します。",
        difficulty: 1,
        problem_type: "fill_in", solution: '文字式では $\times$ を省き、数を文字の前に書きます。だから $a \times 3$ は $3a$ となります。'
      },
      {
        question: '$2x + 3x$ を計算しなさい。',
        answer: "5x",
        hint: "同類項をまとめましょう。",
        difficulty: 1,
        problem_type: "fill_in", solution: '同じ文字どうしはまとめられます。$x$ が $2$ 個と $3$ 個で合わせて $5$ 個、つまり $5x$ です。'
      },
      {
        question: '$3(2x - 4)$ を展開しなさい。（スペースなし、例: 6x-12）',
        answer: "6x-12",
        hint: "かっこの中の各項に3をかけます。",
        difficulty: 2,
        problem_type: "fill_in", solution: 'かっこの外の $3$ を、かっこの中のすべてにかけます。$3 \times 2x = 6x$、$3 \times (-4) = -12$ なので $6x-12$ です。'
      },
      {
        question: '$x = -2$ のとき、$4x - 1$ の値を求めなさい。',
        answer: "-9",
        hint: '$x$ に $-2$ を代入して計算しましょう。',
        difficulty: 2,
        problem_type: "fill_in", solution: '$x$ に $-2$ を入れます。$4 \times (-2) - 1 = -8 - 1 = -9$ です。'
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
        question: '$x + 5 = 12$ を解きなさい。',
        answer: "7",
        hint: "両辺から5を引きましょう。",
        difficulty: 1,
        problem_type: "fill_in", solution: '両辺から $5$ をひきます。$x = 12 - 5 = 7$ です。'
      },
      {
        question: '$3x = 18$ を解きなさい。',
        answer: "6",
        hint: "両辺を3で割りましょう。",
        difficulty: 1,
        problem_type: "fill_in", solution: '両辺を $3$ でわります。$x = 18 \div 3 = 6$ です。'
      },
      {
        question: '$2x - 3 = 7$ を解きなさい。',
        answer: "5",
        hint: "まず両辺に3を足して、次に両辺を2で割りましょう。",
        difficulty: 2,
        problem_type: "fill_in", solution: 'まず $-3$ を移項して $2x = 7 + 3 = 10$。次に両辺を $2$ でわって $x = 5$ です。'
      },
      {
        question: '$4x + 1 = 2x + 9$ を解きなさい。',
        answer: "4",
        hint: "文字を左辺、数を右辺にまとめましょう。",
        difficulty: 3,
        problem_type: "fill_in", solution: '文字を左、数を右に集めます。$4x - 2x = 9 - 1$ で $2x = 8$、両辺を $2$ でわって $x = 4$ です。'
      },
      {
        question: "ある数を3倍して5をひくと16になる。ある数を求めなさい。",
        answer: "7",
        hint: 'ある数を $x$ とおいて方程式を立てましょう。$3x - 5 = 16$',
        difficulty: 3,
        problem_type: "fill_in", solution: 'ある数を $x$ とすると $3x - 5 = 16$ という式が立ちます。$3x = 21$ となり $x = 7$ です。'
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
        question: '$y = 3x$ で、$x = 4$ のときの $y$ の値を求めなさい。',
        answer: "12",
        hint: '$x$ に4を代入しましょう。',
        difficulty: 1,
        problem_type: "fill_in", solution: '$x$ に $4$ を入れます。$y = 3 \times 4 = 12$ です。'
      },
      {
        question: '$y$ が $x$ に比例し、$x = 2$ のとき $y = 10$ です。比例定数を求めなさい。',
        answer: "5",
        hint: '$y = ax$ の $a$ を求めます。$a = y \div x$',
        difficulty: 2,
        problem_type: "fill_in", solution: '比例では $y = ax$ なので、$a = y \div x$ で求まります。$10 \div 2 = 5$ です。'
      },
      {
        question: '$y = \frac{12}{x}$ で、$x = 3$ のときの $y$ の値を求めなさい。',
        answer: "4",
        hint: '$x$ に3を代入しましょう。',
        difficulty: 2,
        problem_type: "fill_in", solution: '$x$ に $3$ を入れます。$y = 12 \div 3 = 4$ です。'
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
      p.solution = pd[:solution]
    end
    fill_solution(problem, pd[:solution])

    choices_data.each do |cd|
      Choice.find_or_create_by!(problem: problem, text: cd[:text]) do |c|
        c.is_correct = cd[:is_correct]
      end
    end
  end
end

# 単元ごとのステータス種別マッピング（1単元に複数書ける。ポイントは均等に分けて入る）
{
  "分数のかけ算・わり算" => [stat_calc],
  "比と比の値"           => [stat_number],
  "速さ・時間・距離"     => [stat_reading],
  "文字と式（小6）"      => [stat_logic],
  "正の数・負の数"       => [stat_calc],
  "文字と式"             => [stat_logic],
  "方程式"               => [stat_logic],
  "比例と反比例"         => [stat_number]
}.each do |title, types|
  Unit.where(title: title).find_each do |unit|
    types.each { |st| UnitStatType.find_or_create_by!(unit: unit, stat_type: st) }
  end
end

# 追加の問題（既存はそのまま、不足分を足す）。title で単元に紐づける。
extra_problems = {
  "分数のかけ算・わり算" => [
    { question: '$\frac{1}{2} \times \frac{4}{5}$ を計算しなさい。（分数は a/b の形で答えること）', answer: "2/5", hint: "分子どうし・分母どうしをかけて約分します。", difficulty: 1, problem_type: "fill_in", solution: '分母どうし・分子どうしをかけて $\frac{4}{10}$。約分して $\frac{2}{5}$ です。' },
    { question: '$\frac{5}{6} \times \frac{3}{10}$ を計算しなさい。（分数は a/b の形で答えること）', answer: "1/4", hint: "先に約分できるか確認しましょう。", difficulty: 2, problem_type: "fill_in", solution: 'かけると $\frac{15}{60}$ で、約分して $\frac{1}{4}$ です。$3$ と $6$、$5$ と $10$ を先に約分すると楽になります。' },
    { question: '$\frac{2}{9} \div \frac{4}{3}$ を計算しなさい。（分数は a/b の形で答えること）', answer: "1/6", hint: 'わる数 $\frac{4}{3}$ を逆数にしてかけます。', difficulty: 2, problem_type: "fill_in", solution: '$\div$ を $\times$ に変えて後ろの分数をひっくり返します。$\frac{2}{9} \times \frac{3}{4} = \frac{6}{36}$ となり、約分して $\frac{1}{6}$ です。' },
    { question: '$\frac{3}{4} \div \frac{6}{7}$ を計算しなさい。（分数は a/b の形で答えること）', answer: "7/8", hint: '$\frac{6}{7}$ を逆数にしてかけ、約分します。', difficulty: 2, problem_type: "fill_in", solution: 'ひっくり返してかけます。$\frac{3}{4} \times \frac{7}{6} = \frac{21}{24}$ となり、約分して $\frac{7}{8}$ です。' },
    { question: '$\frac{2}{3} \times \frac{3}{4} \div \frac{1}{2}$ を計算しなさい。', answer: "1", hint: '左から順に。まず $\frac{2}{3} \times \frac{3}{4} = \frac{1}{2}$、次に $\div \frac{1}{2}$。', difficulty: 3, problem_type: "fill_in", solution: '前から順に計算します。$\frac{2}{3} \times \frac{3}{4} = \frac{1}{2}$、次に $\frac{1}{2} \div \frac{1}{2} = \frac{1}{2} \times \frac{2}{1} = 1$ です。' }
  ],
  "比と比の値" => [
    { question: "8 : 12 を最も簡単な整数の比にしなさい。（a:b の形で答えること）", answer: "2:3", hint: "8と12の最大公約数4で割ります。", difficulty: 1, problem_type: "fill_in", solution: '最大公約数の $4$ で両方をわります。$8 \div 4 = 2$、$12 \div 4 = 3$ なので $2:3$ です。' },
    { question: "15 : 25 を最も簡単な整数の比にしなさい。（a:b の形で答えること）", answer: "3:5", hint: "5で割りましょう。", difficulty: 1, problem_type: "fill_in", solution: '最大公約数の $5$ で両方をわります。$15 \div 5 = 3$、$25 \div 5 = 5$ なので $3:5$ です。' },
    { question: "3 : 4 = 9 : □ の □ に当てはまる数を求めなさい。", answer: "12", hint: "3が9になったので3倍。4も3倍します。", difficulty: 2, problem_type: "fill_in", solution: '$9$ は $3$ の $3$ 倍です。比は両方が同じ倍率になるので、$□$ も $4$ の $3$ 倍で $12$ です。' },
    { question: "10 : 15 = □ : 6 の □ に当てはまる数を求めなさい。", answer: "4", hint: "10:15 を簡単にすると 2:3。それを□:6に合わせます。", difficulty: 2, problem_type: "fill_in", solution: 'まず $10:15$ を簡単にすると $2:3$ です。$6$ は $3$ の $2$ 倍なので、$□$ は $2$ の $2$ 倍で $4$ になります。' },
    { question: "200円をAとBで 3 : 5 に分けます。Bは何円ですか？（単位はつけず数字だけで答えること）", answer: "125", hint: "全体を3+5=8に分け、Bは5つ分。", difficulty: 3, problem_type: "fill_in", solution: '全体を $3+5=8$ とみます。Bは全体の $\frac{5}{8}$ なので、$200 \times \frac{5}{8} = 125$ です。' }
  ],
  "速さ・時間・距離" => [
    { question: "100kmの道のりを4時間で走ったときの速さは、時速何kmですか？（単位はつけず数字だけで答えること）", answer: "25", hint: "速さ＝距離÷時間", difficulty: 1, problem_type: "fill_in", solution: '速さ $=$ 道のり $\div$ 時間 です。$100 \div 4 = 25$ なので時速 $25$ km になります。' },
    { question: "300mの道のりを分速60mで歩くと何分かかりますか？（単位はつけず数字だけで答えること）", answer: "5", hint: "時間＝距離÷速さ", difficulty: 1, problem_type: "fill_in", solution: '時間 $=$ 道のり $\div$ 速さ です。$300 \div 60 = 5$ 分かかります。' },
    { question: "時速60kmで2.5時間走ると何km進みますか？（単位はつけず数字だけで答えること）", answer: "150", hint: "距離＝速さ×時間", difficulty: 2, problem_type: "fill_in", solution: '道のり $=$ 速さ $\times$ 時間 です。$60 \times 2.5 = 150$ なので $150$ km 進みます。' },
    { question: "秒速5mは分速何mですか？（単位はつけず数字だけで答えること）", answer: "300", hint: "1分は60秒。5×60で求めます。", difficulty: 2, problem_type: "fill_in", solution: '1分は $60$ 秒なので、1秒に進む距離を $60$ 倍します。$5 \times 60 = 300$ で分速 $300$ m です。' },
    { question: "時速4kmで3kmの道のりを歩くと何分かかりますか？（単位はつけず数字だけで答えること）", answer: "45", hint: "時間＝3÷4＝0.75時間。分に直します。", difficulty: 3, problem_type: "fill_in", solution: 'かかる時間は $3 \div 4 = 0.75$ 時間です。1時間は $60$ 分なので $0.75 \times 60 = 45$ 分になります。' }
  ],
  "文字と式（小6）" => [
    { question: '1個120円のりんごを $x$ 個買ったときの代金を式で表しなさい。', answer: "120x", hint: "（1個の値段）×（個数）。×は省略。", difficulty: 1, problem_type: "fill_in", solution: '代金 $=$ 1個の値段 $\times$ 個数 なので $120 \times x$ です。$\times$ を省いて $120x$ と書きます。' },
    { question: '$a$ 円の品物を3個買ったときの代金を式で表しなさい。', answer: "3a", hint: "数は文字の前に書きます。", difficulty: 1, problem_type: "fill_in", solution: '$a \times 3$ です。文字式では数を文字の前に書くので $3a$ となります。' },
    { question: '$x = 4$ のとき、$5x$ の値を求めなさい。', answer: "20", hint: '$5 \times 4$ を計算します。', difficulty: 1, problem_type: "fill_in", solution: '$5x$ は $5 \times x$ という意味です。$5 \times 4 = 20$ になります。' },
    { question: '$x = 3$ のとき、$2x + 7$ の値を求めなさい。', answer: "13", hint: '$2 \times 3$ に7を足します。', difficulty: 2, problem_type: "fill_in", solution: '$2 \times 3 + 7 = 6 + 7 = 13$ です。かけ算を先に計算します。' },
    { question: '1本60円の鉛筆を $x$ 本買って500円を出したときのおつりを式で表しなさい。（スペースなし）', answer: "500-60x", hint: "おつり＝出したお金－代金。", difficulty: 3, problem_type: "fill_in", solution: 'おつり $=$ 出したお金 $-$ 代金 です。代金は $60 \times x = 60x$ なので、おつりは $500 - 60x$ となります。' }
  ],
  "正の数・負の数" => [
    { question: '$(-6) + 9$ を計算しなさい。', answer: "3", hint: "符号がちがうときは絶対値の差に大きいほうの符号。", difficulty: 1, problem_type: "fill_in", solution: '符号が違うたし算は、絶対値の大きい方から小さい方をひき、大きい方の符号をつけます。$9 - 6 = 3$ で、$9$ がプラスなので $3$ です。' },
    { question: '$7 - 10$ を計算しなさい。', answer: "-3", hint: "10のほうが大きいので答えは負になります。", difficulty: 1, problem_type: "fill_in", solution: '$7$ から $10$ はひけないので、答えはマイナスになります。$10 - 7 = 3$ なので $-3$ です。' },
    { question: '$(-2) \times 5$ を計算しなさい。', answer: "-10", hint: "負×正＝負", difficulty: 2, problem_type: "fill_in", solution: '符号が違うかけ算の答えはマイナスです。$2 \times 5 = 10$ なので $-10$ になります。' },
    { question: '$(-20) \div (-4)$ を計算しなさい。', answer: "5", hint: "負÷負＝正", difficulty: 2, problem_type: "fill_in", solution: 'マイナス $\div$ マイナスはプラスになります。$20 \div 4 = 5$ なので $5$ です。' }
  ],
  "文字と式" => [
    { question: '$5a - 2a$ を計算しなさい。', answer: "3a", hint: "同類項をまとめます。", difficulty: 1, problem_type: "fill_in", solution: '同じ文字どうしはまとめられます。$a$ が $5$ 個から $2$ 個を取ると $3$ 個、つまり $3a$ です。' },
    { question: '$x \times (-4)$ を文字式の表し方にしなさい。', answer: "-4x", hint: "符号をつけて数を前に、×は省略。", difficulty: 1, problem_type: "fill_in", solution: '$\times$ を省いて数を文字の前に書きます。符号もつけて $-4x$ となります。' },
    { question: '$2(3x + 1)$ を展開しなさい。（スペースなし、例: 6x+2）', answer: "6x+2", hint: "かっこの中の各項に2をかけます。", difficulty: 2, problem_type: "fill_in", solution: 'かっこの外の $2$ を中のすべてにかけます。$2 \times 3x = 6x$、$2 \times 1 = 2$ なので $6x+2$ です。' },
    { question: '$x = -3$ のとき、$2x + 5$ の値を求めなさい。', answer: "-1", hint: '$2 \times (-3)$ に5を足します。', difficulty: 2, problem_type: "fill_in", solution: '$2 \times (-3) + 5 = -6 + 5 = -1$ です。' }
  ],
  "方程式" => [
    { question: '$x - 4 = 9$ を解きなさい。', answer: "13", hint: "両辺に4を足します。", difficulty: 1, problem_type: "fill_in", solution: '両辺に $4$ をたします。$x = 9 + 4 = 13$ です。' },
    { question: '$5x = 35$ を解きなさい。', answer: "7", hint: "両辺を5で割ります。", difficulty: 1, problem_type: "fill_in", solution: '両辺を $5$ でわります。$x = 35 \div 5 = 7$ です。' },
    { question: '$3x + 2 = 14$ を解きなさい。', answer: "4", hint: "まず2を移項、次に3で割ります。", difficulty: 2, problem_type: "fill_in", solution: '$2$ を移項して $3x = 14 - 2 = 12$。両辺を $3$ でわって $x = 4$ です。' },
    { question: '$2x + 3 = x + 8$ を解きなさい。', answer: "5", hint: "xを左、数を右に移項します。", difficulty: 2, problem_type: "fill_in", solution: '文字を左、数を右に集めます。$2x - x = 8 - 3$ となり $x = 5$ です。' }
  ],
  "比例と反比例" => [
    { question: '$y = 5x$ で、$x = 3$ のときの $y$ の値を求めなさい。', answer: "15", hint: '$x$ に3を代入します。', difficulty: 1, problem_type: "fill_in", solution: '$x$ に $3$ を入れます。$y = 5 \times 3 = 15$ です。' },
    { question: '$y = \frac{24}{x}$ で、$x = 6$ のときの $y$ の値を求めなさい。', answer: "4", hint: "24を6で割ります。", difficulty: 1, problem_type: "fill_in", solution: '$x$ に $6$ を入れます。$y = 24 \div 6 = 4$ です。' },
    { question: '$y = -2x$ で、$x = 4$ のときの $y$ の値を求めなさい。', answer: "-8", hint: '$-2 \times 4$ を計算します。', difficulty: 2, problem_type: "fill_in", solution: '$y = (-2) \times 4 = -8$ です。符号を落とさないように気をつけます。' },
    { question: '$y$ が $x$ に比例し、$x = 3$ のとき $y = 12$ です。比例定数を求めなさい。', answer: "4", hint: '$a = y \div x$ で求めます。', difficulty: 2, problem_type: "fill_in", solution: '比例定数は $a = y \div x$ で求まります。$12 \div 3 = 4$ です。' }
  ]
}

extra_problems.each do |title, probs|
  unit = Unit.find_by(title: title)
  next unless unit

  probs.each do |pd|
    problem_row = Problem.find_or_create_by!(question: pd[:question], unit: unit) do |p|
      p.answer = pd[:answer]
      p.hint = pd[:hint]
      p.difficulty = pd[:difficulty]
      p.problem_type = pd[:problem_type]
      p.solution = pd[:solution]
    end
    # find_or_create_by! のブロックは新規作成のときしか走らない。
    # 解説をあとから足したので、すでにある問題にも入れる（空のときだけ＝管理画面の編集は残す）。
    fill_solution(problem_row, pd[:solution])
  end
end

# 難易度の上のほう（3〜5）の問題。習熟度に応じた出題を効かせるには、
# 単元ごとに難易度の幅が要る（幅がないと「中心難易度」を決めても選びようがない）。
# 注意: LaTeX を含む文字列は必ずシングルクォート。ダブルクォートだと \frac が
# 改ページ文字、\times がタブに化ける。
advanced_problems = {
  "分数のかけ算・わり算" => [
    { question: '$\frac{9}{10} \times \frac{4}{3} \div 2$ を計算しなさい。（分数は a/b の形で答えること）',
      answer: "3/5", hint: '前から順に計算します。÷2 は $\times \frac{1}{2}$ と同じです。', difficulty: 4, problem_type: "fill_in", solution: '前から計算します。$\frac{9}{10} \times \frac{4}{3} = \frac{6}{5}$、次に $\div 2$ は $\times \frac{1}{2}$ なので $\frac{6}{10} = \frac{3}{5}$ です。' },
    { question: '$\frac{3}{4}$ Lのジュースを、1人に $\frac{1}{8}$ Lずつ分けると何人に分けられますか？（単位はつけず数字だけで答えること）',
      answer: "6", hint: "「いくつ分か」を求めるのでわり算です。", difficulty: 4, problem_type: "fill_in", solution: '何人分かは、全体を1人分でわって求めます。$\frac{3}{4} \div \frac{1}{8} = \frac{3}{4} \times \frac{8}{1} = 6$ 人です。' },
    { question: '面積が $\frac{5}{6}$ m² の長方形の花だんがあります。たての長さが $\frac{2}{3}$ m のとき、横の長さは何mですか？（単位はつけず、分数は a/b の形で答えること）',
      answer: "5/4", hint: "横 = 面積 ÷ たて です。", difficulty: 5, problem_type: "fill_in", solution: '横 $=$ 面積 $\div$ たて です。$\frac{5}{6} \div \frac{2}{3} = \frac{5}{6} \times \frac{3}{2} = \frac{15}{12}$ となり、約分して $\frac{5}{4}$ です。' }
  ],
  "比と比の値" => [
    { question: '$A : B = 2 : 3$、$B : C = 4 : 5$ のとき、$A : C$ を最も簡単な整数の比で答えなさい。（a:b の形で答えること）',
      answer: "8:15", hint: "Bの数をそろえます。2:3 は 8:12、4:5 は 12:15 にできます。", difficulty: 4, problem_type: "fill_in", solution: '共通する $B$ の数をそろえます。$B$ を $12$ にすると $A:B = 8:12$、$B:C = 12:15$ となるので、$A:C = 8:15$ です。' },
    { question: '兄と弟の所持金の比は $5 : 3$ です。兄が弟より400円多いとき、兄の所持金は何円ですか？（単位はつけず数字だけで答えること）',
      answer: "1000", hint: "比の差の2が400円にあたります。", difficulty: 4, problem_type: "fill_in", solution: '比の差 $5-3=2$ が $400$ 円にあたります。比の $1$ が $200$ 円なので、兄は $5 \times 200 = 1000$ 円です。' },
    { question: '420円を $A : B : C = 2 : 3 : 5$ の割合で分けます。Bは何円ですか？（単位はつけず数字だけで答えること）',
      answer: "126", hint: "全部で 2+3+5=10 にあたります。1にあたる金額から求めます。", difficulty: 5, problem_type: "fill_in", solution: '全体を $2+3+5=10$ とみます。Bは全体の $\frac{3}{10}$ なので $420 \times \frac{3}{10} = 126$ 円です。' }
  ],
  "速さ・時間・距離" => [
    { question: '時速72kmは秒速何mですか？（単位はつけず数字だけで答えること）',
      answer: "20", hint: "72km=72000m、1時間=3600秒です。", difficulty: 4, problem_type: "fill_in", solution: '1時間は $3600$ 秒、$72$ km は $72000$ m です。$72000 \div 3600 = 20$ なので秒速 $20$ m になります。' },
    { question: '4kmの道のりを、はじめの2kmは分速50m、残りの2kmは分速80mで歩きました。合わせて何分かかりましたか？（単位はつけず数字だけで答えること）',
      answer: "65", hint: "前半と後半の時間をそれぞれ出してから足します。", difficulty: 4, problem_type: "fill_in", solution: '$2$ km $= 2000$ m です。前半は $2000 \div 50 = 40$ 分、後半は $2000 \div 80 = 25$ 分。合わせて $65$ 分になります。' },
    { question: '家から学校までの1.2kmを、分速60mで歩くかわりに分速80mで走ると、何分早く着きますか？（単位はつけず数字だけで答えること）',
      answer: "5", hint: "それぞれかかる時間を出して、その差を求めます。", difficulty: 5, problem_type: "fill_in", solution: '$1.2$ km $= 1200$ m です。歩くと $1200 \div 60 = 20$ 分、走ると $1200 \div 80 = 15$ 分。差は $5$ 分です。' }
  ],
  "文字と式（小6）" => [
    { question: '1個 $a$ 円のパンを5個と、1本 $b$ 円のジュースを3本買ったときの代金を式で表しなさい。（スペースなし）',
      answer: "5a+3b", hint: "パンの代金とジュースの代金を足します。", difficulty: 4, problem_type: "fill_in", solution: 'パンの代金は $a \times 5 = 5a$、ジュースは $b \times 3 = 3b$ です。合わせて $5a+3b$ となります。' },
    { question: '$x = 6$ のとき、$\frac{x}{2} + 4$ の値を求めなさい。',
      answer: "7", hint: '$x$ に6を入れてから、わり算を先に計算します。', difficulty: 4, problem_type: "fill_in", solution: '$6 \div 2 + 4 = 3 + 4 = 7$ です。わり算を先に計算します。' },
    { question: '$x = 6$、$y = 2$ のとき、$\frac{x}{y} + 4y$ の値を求めなさい。',
      answer: "11", hint: "それぞれの文字に数を入れてから計算します。", difficulty: 5, problem_type: "fill_in", solution: '$6 \div 2 + 4 \times 2 = 3 + 8 = 11$ です。わり算とかけ算を先に計算します。' }
  ],
  "正の数・負の数" => [
    { question: '$(-2)^3$ を計算しなさい。',
      answer: "-8", hint: '$(-2) \times (-2) \times (-2)$ です。負の数を3回かけると符号は負になります。', difficulty: 3, problem_type: "fill_in", solution: '$(-2)$ を $3$ 回かけます。$(-2) \times (-2) \times (-2) = -8$ です。マイナスを奇数回かけると答えはマイナスになります。' },
    { question: '$(-3) \times 4 + 6$ を計算しなさい。',
      answer: "-6", hint: "かけ算を先に計算します。", difficulty: 3, problem_type: "fill_in", solution: 'かけ算が先です。$(-3) \times 4 = -12$、それに $6$ をたして $-6$ になります。' },
    { question: '$(-2)^2 \times (-3)$ を計算しなさい。',
      answer: "-12", hint: '$(-2)^2$ は $(-2) \times (-2) = 4$ です。', difficulty: 4, problem_type: "fill_in", solution: '$(-2)^2 = 4$ です（マイナスを偶数回かけるとプラス）。$4 \times (-3) = -12$ になります。' },
    { question: '$12 \div (-4) - (-5)$ を計算しなさい。',
      answer: "2", hint: "わり算を先に。うしろは「−（−5）」なので+5になります。", difficulty: 4, problem_type: "fill_in", solution: 'わり算が先で $12 \div (-4) = -3$。次に $-3 - (-5) = -3 + 5 = 2$ です。' },
    { question: '$(-3)^2 - 4 \times (-2) + (-6) \div 3$ を計算しなさい。',
      answer: "15", hint: "累乗 → かけ算・わり算 → たし算・ひき算 の順に計算します。", difficulty: 5, problem_type: "fill_in", solution: '累乗が先で $(-3)^2 = 9$。次にかけ算とわり算で $4 \times (-2) = -8$、$(-6) \div 3 = -2$。最後に $9 - (-8) + (-2) = 9 + 8 - 2 = 15$ です。' }
  ],
  "文字と式" => [
    { question: '$5x - 2(x - 3)$ を計算しなさい。（スペースなし、例: 4x+5）',
      answer: "3x+6", hint: "かっこを外すとき、−2をかけることに注意します。", difficulty: 3, problem_type: "fill_in", solution: 'かっこを外します。$-2 \times x = -2x$、$-2 \times (-3) = +6$ です。$5x - 2x + 6 = 3x+6$ になります。' },
    { question: '$-3(2x - 5)$ を展開しなさい。（スペースなし、例: 4x+5）',
      answer: "-6x+15", hint: "かっこの中の両方に −3 をかけます。", difficulty: 3, problem_type: "fill_in", solution: '$-3$ をかっこの中のすべてにかけます。$-3 \times 2x = -6x$、$-3 \times (-5) = +15$ なので $-6x+15$ です。' },
    { question: '$2(3x - 1) - 3(x - 4)$ を計算しなさい。（スペースなし、例: 4x+5）',
      answer: "3x+10", hint: "先に両方のかっこを外してから、同じ文字どうしをまとめます。", difficulty: 4, problem_type: "fill_in", solution: 'それぞれ展開すると $6x-2$ と $-3x+12$ になります。$6x - 3x = 3x$、$-2 + 12 = 10$ なので $3x+10$ です。' },
    { question: '$x = -2$ のとき、$x^2 - 3x$ の値を求めなさい。',
      answer: "10", hint: '$x^2$ は $(-2) \times (-2)$ です。負の数の代入はかっこをつけて考えます。', difficulty: 4, problem_type: "fill_in", solution: '$(-2)^2 = 4$、$-3 \times (-2) = +6$ です。$4 + 6 = 10$ になります。' },
    { question: '$a = -3$ のとき、$2a^2 + 5a - 4$ の値を求めなさい。',
      answer: "-1", hint: '$a^2 = 9$ を先に出してから、順に計算します。', difficulty: 5, problem_type: "fill_in", solution: '$a^2 = 9$ なので $2 \times 9 = 18$。$5 \times (-3) = -15$ です。$18 - 15 - 4 = -1$ になります。' }
  ],
  "方程式" => [
    { question: '$3(x - 2) = x + 4$ を解きなさい。',
      answer: "5", hint: "まずかっこを外し、xを左、数を右に移項します。", difficulty: 4, problem_type: "fill_in", solution: '左を展開して $3x - 6 = x + 4$。文字を左、数を右に集めて $2x = 10$、両辺を $2$ でわって $x = 5$ です。' },
    { question: '$\frac{x}{3} + 2 = 5$ を解きなさい。',
      answer: "9", hint: "先に2を移項してから、両辺に3をかけます。", difficulty: 4, problem_type: "fill_in", solution: '$2$ を移項して $\frac{x}{3} = 3$。両辺を $3$ 倍して $x = 9$ です。' },
    { question: '1個150円のケーキと1個90円のプリンを合わせて8個買ったら、代金は900円でした。ケーキは何個買いましたか？（単位はつけず数字だけで答えること）',
      answer: "3", hint: "ケーキを $x$ 個とすると、プリンは $8 - x$ 個です。", difficulty: 5, problem_type: "fill_in", solution: 'ケーキを $x$ 個とすると、プリンは $8-x$ 個です。$150x + 90(8-x) = 900$ より $60x + 720 = 900$ となり、$x = 3$ 個です。' }
  ],
  "比例と反比例" => [
    { question: '$y$ が $x$ に反比例し、$x = 4$ のとき $y = 6$ です。比例定数を求めなさい。',
      answer: "24", hint: '反比例では $x \times y$ が比例定数になります。', difficulty: 3, problem_type: "fill_in", solution: '反比例では $y = \frac{a}{x}$ なので、$a = x \times y$ で求まります。$4 \times 6 = 24$ です。' },
    { question: '$y = -3x$ で、$y = 12$ のときの $x$ の値を求めなさい。',
      answer: "-4", hint: '$12 = -3x$ とみて、両辺を $-3$ で割ります。', difficulty: 3, problem_type: "fill_in", solution: '$12 = -3x$ という式になります。両辺を $-3$ でわって $x = -4$ です。' },
    { question: '$y$ が $x$ に比例し、$x = 2$ のとき $y = -6$ です。$x = 5$ のときの $y$ の値を求めなさい。',
      answer: "-15", hint: '先に比例定数 $a = y \div x$ を求めます。', difficulty: 4, problem_type: "fill_in", solution: 'まず比例定数を出します。$a = -6 \div 2 = -3$ なので $y = -3x$。$x = 5$ を入れて $y = -15$ です。' },
    { question: '$y$ が $x$ に反比例し、$x = 3$ のとき $y = 8$ です。$x = 6$ のときの $y$ の値を求めなさい。',
      answer: "4", hint: '先に比例定数 $x \times y$ を求めます。', difficulty: 4, problem_type: "fill_in", solution: '比例定数は $a = 3 \times 8 = 24$ なので $y = \frac{24}{x}$。$x = 6$ を入れて $y = 4$ です。' },
    { question: '$y$ が $x$ に反比例し、$x = -2$ のとき $y = 9$ です。$y = -6$ のときの $x$ の値を求めなさい。',
      answer: "3", hint: '比例定数は $(-2) \times 9$ です。そこから $x = a \div y$ で求めます。', difficulty: 5, problem_type: "fill_in", solution: '比例定数は $a = (-2) \times 9 = -18$ なので $y = \frac{-18}{x}$。$-6 = \frac{-18}{x}$ より $x = 3$ です。' }
  ]
}

advanced_problems.each do |title, probs|
  unit = Unit.find_by(title: title)
  next unless unit

  probs.each do |pd|
    problem_row = Problem.find_or_create_by!(question: pd[:question], unit: unit) do |p|
      p.answer = pd[:answer]
      p.hint = pd[:hint]
      p.difficulty = pd[:difficulty]
      p.problem_type = pd[:problem_type]
      p.solution = pd[:solution]
    end
    # find_or_create_by! のブロックは新規作成のときしか走らない。
    # 解説をあとから足したので、すでにある問題にも入れる（空のときだけ＝管理画面の編集は残す）。
    fill_solution(problem_row, pd[:solution])
  end
end

# 単元ごとの教材（解説）Markdown。既存単元にも反映されるよう update で入れる。
lessons = {
  # 数式は KaTeX（$...$ / $$...$$）。バックスラッシュを守るため
  # ヒアドキュメントは必ずリテラル（<<~'MD'）にすること。
  # <<~MD だと \frac が改ページ文字、\times がタブに化けて数式が壊れる。
  "分数のかけ算・わり算" => <<~'MD',
    ## 分数のかけ算・わり算

    ケーキやジュースを「何等分の何こ分」と考えるときに使うのが分数です。かけ算・わり算は、ルールさえ覚えれば整数の計算よりもむしろ単純です。

    ### かけ算のやり方
    **分子どうし・分母どうしをかける**だけです。

    $$
    \frac{2}{3} \times \frac{3}{4} = \frac{2 \times 3}{3 \times 4} = \frac{6}{12} = \frac{1}{2}
    $$

    最後に**約分**するのを忘れずに。かける前に約分できるときは、先に約分すると数が小さくなって計算が楽です。

    ### わり算のやり方
    **わる数をひっくり返して（逆数にして）かける**だけです。

    $$
    \frac{4}{7} \div \frac{2}{3} = \frac{4}{7} \times \frac{3}{2} = \frac{12}{14} = \frac{6}{7}
    $$

    ### れいだい
    $\frac{3}{5} \times \frac{5}{6}$ を計算しよう。

    1. 分子どうし・分母どうしをかける → $\frac{3 \times 5}{5 \times 6} = \frac{15}{30}$
    2. 約分する → $\frac{15}{30} = \frac{1}{2}$

    （先に約分してもOK：5どうしを消して $\frac{3}{6} = \frac{1}{2}$）

    ### よくあるまちがい
    - ❌ わり算で、分母どうし・分子どうしをそのまま割る
    - ⭕ わり算は「ひっくり返してかける」に直す
    - ❌ 約分をわすれて $\frac{6}{12}$ のままにする
    - ⭕ 答えは必ず「これ以上約分できないか」を確認する

    ### ポイント
    - かけ算は $\frac{a}{b} \times \frac{c}{d} = \frac{a \times c}{b \times d}$
    - わり算は $\frac{a}{b} \div \frac{c}{d} = \frac{a}{b} \times \frac{d}{c}$
    - 答えは必ず約分できないか確認する
  MD

  "比と比の値" => <<~'MD',
    ## 比と比の値

    「牛乳とコーヒーを $3 : 2$ でまぜる」のように、**2つの量の割合**を表すのが比です。料理や地図、拡大・縮小など身のまわりでよく使います。

    ### 比の値
    $a : b$ の**比の値**は $\frac{a}{b}$ です。$3 : 2$ なら $\frac{3}{2}$。

    ### 比を簡単にする
    両方を**同じ数で割る**と、比は簡単になります（比の値は変わりません）。

    - $6 : 9$ → 6と9を3で割って $2 : 3$

    ### 等しい比
    $4 : 6 = \square : 9$ は、**何倍になったか**を考えます。

    - 6 が 9 になるには1.5倍。だから 4 も1.5倍して **6**

    ### 全体を分ける
    「$3 : 2$ に分ける」なら、全体を $3 + 2 = 5$ に分けて考えます。

    ### れいだい
    120mL のジュースを A と B で $3 : 2$ に分けよう。A は何mL？

    1. 全体を $3 + 2 = 5$ に分ける
    2. 1つ分は $120 \div 5 = 24$ mL
    3. A は3つ分なので $24 \times 3 = 72$ mL

    ### よくあるまちがい
    - ❌ 「$3 : 2$ に分ける」で、全体を3で割ってしまう
    - ⭕ まず $3 + 2 = 5$ で全体をいくつに分けるか出す
    - ❌ 比を簡単にするとき、片方だけ割る
    - ⭕ 両方を同じ数で割る

    ### ポイント
    - 比は同じ数で割っても等しい
    - 分けるときは「全体をいくつに分けるか」をまず出す
  MD

  "速さ・時間・距離" => <<~'MD',
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
    2. 時間 ＝ 距離 ÷ 速さ ＝ $2400 \div 80 = 30$ 分

    ### よくあるまちがい
    - ❌ km と m など、単位がちがうまま計算する
    - ⭕ まず単位をそろえてから計算する
    - ❌ どれを割ればいいか毎回まよう
    - ⭕ 「距離＝速さ×時間」を1つ覚えれば、あとは逆算で出る

    ### ポイント
    - 「み・は・じ」（道のり・速さ・時間）の関係を1つ覚える
    - まず単位をそろえる
  MD

  "文字と式（小6）" => <<~'MD',
    ## 文字と式（小6）

    まだわからない数や、あとで変わる数を**文字**（$x$ など）で表すと、いろいろな場面を1つの式で書けます。買い物の代金の計算などで便利です。

    ### 式で表す
    - 1本80円の鉛筆を $x$ 本 → 代金は $80 \times x = 80x$
    - ×の記号は**省略**し、数を文字の前に書きます。

    ### 代入する
    文字に数を当てはめて計算することを**代入**といいます。

    ### れいだい
    $x = 5$ のとき、$3x + 2$ の値を求めよう。

    1. $x$ を 5 に置きかえる → $3 \times 5 + 2$
    2. 計算する → $15 + 2 = 17$

    ### よくあるまちがい
    - ❌ $80x$ を「80 たす $x$」だと思う
    - ⭕ $80x$ は「80 かける $x$」（×を省略しただけ）
    - ❌ $3x$ に $x = 5$ を入れて「35」と書く
    - ⭕ $3x$ は $3 \times x$ なので $3 \times 5 = 15$

    ### ポイント
    - 「×」は省略。$80 \times x$ は $80x$
    - 代入は「文字を数に置きかえる」だけ
  MD

  "正の数・負の数" => <<~'MD',
    ## 正の数・負の数

    気温の「−3℃」や地下の「−2階」のように、0より小さい数＝**負の数**は生活の中にもあります。数直線で考えると分かりやすいです。

    ### 大小
    数直線で**右にあるほど大きい**。だから $-5 < -1 < 0 < 3$。

    ### たし算・ひき算
    - 同じ符号どうしのたし算：絶対値を足して符号をつける → $(-3) + (-5) = -8$
    - ひき算は「引く数の符号を変えてたし算」→ $(-4) - (-7) = (-4) + 7 = 3$

    ### かけ算・わり算
    符号のルールはシンプルです。

    - 同じ符号どうし → **＋**：$(-3) \times (-4) = 12$
    - ちがう符号どうし → **−**：$(-12) \div (+3) = -4$

    ### れいだい
    $(-4) - (-7)$ を計算しよう。

    1. $-(-7)$ は符号を変えて $+7$
    2. $(-4) + 7 = 3$

    ### よくあるまちがい
    - ❌ $(-4) - (-7)$ を $-4 - 7 = -11$ としてしまう
    - ⭕ 引く数の符号を変えて $(-4) + 7 = 3$
    - ❌ 負×負を負にしてしまう
    - ⭕ 負×負＝**正**

    ### ポイント
    - 負×負＝正、負×正＝負
    - ひき算は符号を変えてたし算に直す
  MD

  "文字と式" => <<~'MD',
    ## 文字と式（中1）

    小6で習った文字式を、中学ではもっと整理して計算します。式を「きれいにまとめる」練習です。

    ### 書き方のルール
    - ×は省略、数は文字の前：$a \times 3 \rightarrow 3a$
    - 同じ文字どうしはまとめられる（**同類項**）：$2x + 3x = 5x$

    ### かっこを外す（分配法則）
    かっこの前の数を、**中の全部の項に**かけます。

    $$
    3(2x - 4) = 3 \times 2x - 3 \times 4 = 6x - 12
    $$

    ### れいだい
    $2(3x + 1)$ を展開しよう。

    1. かっこの前の2を $3x$ にかける → $6x$
    2. 2を $+1$ にもかける → $+2$
    3. 合わせて $6x + 2$

    ### よくあるまちがい
    - ❌ $3(2x - 4)$ で、最初の項だけにかけて $6x - 4$
    - ⭕ **中の全部の項**にかける → $6x - 12$
    - ❌ $2x + 3$ を $5x$ とまとめる（文字と数はまとまらない）
    - ⭕ まとめられるのは同じ文字どうし（$2x$ と $3x$ など）

    ### ポイント
    - 同類項（同じ文字）はまとめる
    - かっこは1つ1つの項にかけて外す
  MD

  "方程式" => <<~'MD',
    ## 方程式

    「ある数を3倍して5ひくと16。ある数は？」——こんな“逆算パズル”を、式できちんと解くのが方程式です。$x$ を使えば、むずかしい文章題も手順どおりに解けます。

    ### 基本の考え方
    **両辺に同じことをしても、＝は成り立つ**。これを使って $x$ だけを残します。

    - $x + 5 = 12$ → 両辺から5を引く → $x = 7$
    - $3x = 18$ → 両辺を3で割る → $x = 6$

    ### 移項
    文字を左、数を右に集めます。反対側に移すと**符号が変わる**（＝移項）。

    ### れいだい
    $2x - 3 = 7$ を解こう。

    1. $-3$ を右に移項（符号が変わって $+3$）→ $2x = 7 + 3 = 10$
    2. 両辺を2で割る → $x = 5$

    ### よくあるまちがい
    - ❌ 移項したのに符号を変えない（$2x = 7 - 3$ とする）
    - ⭕ 移項すると符号が変わる → $2x = 7 + 3$
    - ❌ $3x = 18$ を $x = 18 - 3$ とする
    - ⭕ かけ算は「割る」でほどく → $x = 18 \div 3$

    ### ポイント
    - 両辺に同じ操作をする
    - 移項したら符号が変わる
  MD

  "比例と反比例" => <<~'MD',
    ## 比例と反比例

    「時間が2倍になると進む距離も2倍」——このように、片方が増えるともう片方も決まった割合で変わる関係を式にします。

    ### 比例：$y = ax$
    $x$ が2倍・3倍になると、$y$ も2倍・3倍になる関係。$a$ を**比例定数**といいます。

    - $y = 3x$ で $x = 4$ → $y = 3 \times 4 = 12$

    ### 反比例：$y = \frac{a}{x}$
    $x$ が2倍になると $y$ は $\frac{1}{2}$ になる関係（**$x \times y$ が一定**）。

    - $y = \frac{12}{x}$ で $x = 3$ → $y = 12 \div 3 = 4$

    ### れいだい
    $y$ は $x$ に比例し、$x = 2$ のとき $y = 10$。比例定数 $a$ を求めよう。

    1. 比例は $y = ax$
    2. $a = y \div x = 10 \div 2 = 5$（式は $y = 5x$）

    ### よくあるまちがい
    - ❌ 比例定数を $y \times x$ で求める
    - ⭕ 比例は $a = y \div x$
    - ❌ 反比例なのに $y = ax$ で考える
    - ⭕ 反比例は $y = \frac{a}{x}$（$x \times y$ が一定）

    ### ポイント
    - 比例は $y = ax$（わり算で $a$ が出る）
    - 反比例は $y = \frac{a}{x}$（$x \times y$ が一定）
  MD
}

lessons.each do |title, body|
  Unit.where(title: title).update_all(lesson_body: body)
end

# === 総合ランク ===
# 全ステータスの合計ポイントで到達を判定する。参考目標の合計は 500〜1750pt なので、
# その道中に昇格イベントが並ぶよう刻んでいる（最初の昇格は2〜3問で来る）。
# display_order をキーに更新するので、しきい値の調整は seed の書き換えだけで効く。
[
  ["10級",   0],
  ["9級",    30],
  ["8級",    80],
  ["7級",   150],
  ["6級",   250],
  ["5級",   400],
  ["4級",   600],
  ["3級",   850],
  ["2級",  1150],
  ["1級",  1500],
  ["初段", 2000]
].each_with_index do |(name, threshold), i|
  rank = Rank.find_or_initialize_by(display_order: i + 1)
  rank.name = name
  rank.threshold_points = threshold
  rank.exam_question_count = 10
  rank.pass_percent = 80
  rank.save!
end

puts "Seed完了: #{Grade.count}学年, #{Unit.count}単元, #{Problem.count}問題, #{StatType.count}ステータス種別, 教材#{lessons.size}件, ランク#{Rank.count}段階"

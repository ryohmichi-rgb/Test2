# 管理者の指定（ADMIN_USERNAME のユーザーを管理者にする。存在すれば毎回反映）
# 解説（solution）を、まだ入っていない問題にだけ入れる。
# find_or_create_by! のブロックは新規作成のときしか走らないので、これが無いと
# あとから足した解説が既存の問題に反映されない。
# 「空のときだけ」にしているのは、管理画面で直した解説を seed が上書きしないため。
def fill_solution(problem, solution)
  return if solution.blank? || problem.solution.present?
  problem.update!(solution: solution)
end

# 単元名 => 問題の配列、をまとめて作る。問題文をキーに探すので、
# 既存の問題文を変えると別レコードとして増えてしまう点に注意（変えるなら移行を添える）。
#
# 選択式（problem_type: "multiple_choice"）は :choices を持たせる。
# **採点は平文比較なので、answer は正解の選択肢の文字列とぴったり同じにすること**
# （画面は選んだ選択肢の text をそのまま送る）。
def create_problems(map)
  map.each do |title, probs|
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
      fill_solution(problem_row, pd[:solution])

      (pd[:choices] || []).each do |cd|
        Choice.find_or_create_by!(problem: problem_row, text: cd[:text]) { |c| c.is_correct = cd[:is_correct] }
      end
    end
  end
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
stat_vocab   = StatType.find_or_create_by!(name: "語彙力")    { |s| s.description = "漢字・ことばの意味を知り、使い分ける力"; s.display_order = 6 }

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
  { label: "難関高校受験",     stat_type: stat_vocab,   value: 300 },
  { label: "高校受験（公立）", stat_type: stat_vocab,   value: 200 },
  { label: "中学卒業レベル",   stat_type: stat_vocab,   value: 150 },

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
# ランクを数える「教科のまとまり」。算数（小6）と数学（中1）は学年と1対1で
# ひとつながりの積み上げなので、ランクは分けずに1つにまとめる。
math_group = SubjectGroup.find_or_create_by!(name: "算数・数学") { |g| g.display_order = 0 }
math_e = Subject.find_or_create_by!(name: "算数") { |s| s.subject_group = math_group }
math_m = Subject.find_or_create_by!(name: "数学") { |s| s.subject_group = math_group }
# find_or_create_by! のブロックは新規作成のときしか走らないので、既存行にも入れておく
# （まとまり未設定のときだけ。管理画面で移した設定は上書きしない）
[math_e, math_m].each { |s| s.update!(subject_group: math_group) if s.subject_group_id.nil? }

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

create_problems(extra_problems)

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

create_problems(advanced_problems)

# 難易度の上のほうを厚くする第2弾。各単元を「難易度3・4・5をそれぞれ3問以上」にそろえる。
# 上の幅が薄いと、習熟度の高い子は難しい問題をすぐ解き切ってしまい、
# 以後は解き直し（満点の20%）ばかりになる。ロジックと問題はセットで用意する。
#
# 答えはキーパッド（AnswerInput の KEYPAD_ROWS）で打てる文字だけにする。
# 小数点が無いので、割り切れない答えは分数（a/b）にするか、割り切れる数にしてある。
#
# 注意: LaTeX を含む文字列は必ずシングルクォート。ダブルクォートだと \frac が
# 改ページ文字、\times がタブに化ける。
advanced_problems_2 = {
  "分数のかけ算・わり算" => [
    { question: '$\frac{2}{5} \div \frac{3}{10} \times \frac{1}{4}$ を計算しなさい。（分数は a/b の形で答えること）',
      answer: "1/3", hint: 'わり算を先にかけ算に直してから、左から順に計算します。', difficulty: 3, problem_type: "fill_in",
      solution: '$\div \frac{3}{10}$ を $\times \frac{10}{3}$ に直します。$\frac{2}{5} \times \frac{10}{3} = \frac{20}{15} = \frac{4}{3}$、続けて $\times \frac{1}{4}$ で $\frac{4}{12} = \frac{1}{3}$ です。' },
    { question: '$\frac{5}{9}$ の逆数と $\frac{3}{10}$ の積を求めなさい。（分数は a/b の形で答えること）',
      answer: "27/50", hint: '逆数は分母と分子を入れかえた数です。', difficulty: 3, problem_type: "fill_in",
      solution: '$\frac{5}{9}$ の逆数は $\frac{9}{5}$ です。$\frac{9}{5} \times \frac{3}{10} = \frac{27}{50}$ となり、これ以上は約分できません。' },
    { question: '$\frac{7}{8}$ kgの砂糖を $\frac{7}{24}$ kgずつ袋に分けると、何袋できますか？（単位はつけず数字だけで答えること）',
      answer: "3", hint: '「いくつ分か」を聞かれているのでわり算です。', difficulty: 4, problem_type: "fill_in",
      solution: '$\frac{7}{8} \div \frac{7}{24} = \frac{7}{8} \times \frac{24}{7} = \frac{24}{8} = 3$ です。$7$ どうしが約分できます。' },
    { question: 'ある数に $\frac{3}{4}$ をかけるところを、まちがえて $\frac{3}{4}$ でわってしまい、答えが $\frac{8}{3}$ になりました。正しい答えを求めなさい。（分数は a/b の形で答えること）',
      answer: "3/2", hint: 'まず「ある数」を求めます。わった答えが分かっているので、逆にたどります。', difficulty: 5, problem_type: "fill_in",
      solution: 'ある数を $\square$ とすると $\square \div \frac{3}{4} = \frac{8}{3}$。よって $\square = \frac{8}{3} \times \frac{3}{4} = 2$ です。正しくはこれに $\frac{3}{4}$ をかけて $2 \times \frac{3}{4} = \frac{3}{2}$ となります。' },
    { question: '$\frac{3}{4}$ Lのジュースがあります。まず全体の $\frac{2}{3}$ を飲み、そのあと残りの $\frac{1}{2}$ を妹にあげました。残っているジュースは何Lですか？（単位はつけず、分数は a/b の形で答えること）',
      answer: "1/8", hint: '「全体の $\frac{2}{3}$ を飲む」と、残りは全体の $\frac{1}{3}$ です。', difficulty: 5, problem_type: "fill_in",
      solution: '$\frac{2}{3}$ 飲むと残りは $\frac{1}{3}$ なので $\frac{3}{4} \times \frac{1}{3} = \frac{1}{4}$ L。その半分をあげるので $\frac{1}{4} \times \frac{1}{2} = \frac{1}{8}$ L 残ります。' }
  ],
  "比と比の値" => [
    { question: '$\frac{2}{3} : \frac{4}{9}$ を最も簡単な整数の比で答えなさい。（a:b の形で答えること）',
      answer: "3:2", hint: '分母をそろえてから、分子どうしの比にします。', difficulty: 3, problem_type: "fill_in",
      solution: '分母を $9$ にそろえると $\frac{6}{9} : \frac{4}{9}$ なので $6 : 4$。両方を $2$ でわって $3 : 2$ です。' },
    { question: 'たてと横の長さの比が $3 : 5$ の長方形があります。まわりの長さが48cmのとき、横の長さは何cmですか？（単位はつけず数字だけで答えること）',
      answer: "15", hint: 'まわりの長さは（たて＋横）の2倍です。', difficulty: 4, problem_type: "fill_in",
      solution: 'たてを $3a$、横を $5a$ とすると、まわりは $(3a + 5a) \times 2 = 16a$。$16a = 48$ より $a = 3$ なので、横は $5 \times 3 = 15$ cm です。' },
    { question: '$A : B = 3 : 4$、$B : C = 6 : 7$ のとき、$A : B : C$ を最も簡単な整数の比で答えなさい。（a:b:c の形で答えること）',
      answer: "9:12:14", hint: '共通する $B$ の数をそろえます。$4$ と $6$ の最小公倍数は $12$ です。', difficulty: 5, problem_type: "fill_in",
      solution: '$B$ を $12$ にそろえます。$A : B = 3 : 4 = 9 : 12$、$B : C = 6 : 7 = 12 : 14$。つなげて $9 : 12 : 14$ です。' },
    { question: '兄と弟の所持金の比は $7 : 4$ でしたが、兄が弟に400円わたしたので比は $5 : 4$ になりました。はじめの兄の所持金は何円ですか？（単位はつけず数字だけで答えること）',
      answer: "3150", hint: 'はじめを $7a$ 円と $4a$ 円とおいて、わたしたあとの比の式を作ります。', difficulty: 5, problem_type: "fill_in",
      solution: 'はじめを $7a$ 円、$4a$ 円とおくと、あとは $7a - 400$ と $4a + 400$。これが $5 : 4$ なので $4(7a - 400) = 5(4a + 400)$、つまり $28a - 1600 = 20a + 2000$ より $8a = 3600$、$a = 450$。兄は $7 \times 450 = 3150$ 円です。' }
  ],
  "速さ・時間・距離" => [
    { question: '秒速15mは時速何kmですか？（単位はつけず数字だけで答えること）',
      answer: "54", hint: '1時間は3600秒、1kmは1000mです。', difficulty: 3, problem_type: "fill_in",
      solution: '1時間に進む道のりは $15 \times 3600 = 54000$ m。$1000$ でわって km に直すと時速 $54$ km です。' },
    { question: '6kmの道のりを、行きは時速4km、帰りは時速6kmで往復しました。往復にかかった時間は何時間ですか？（単位はつけず、分数は a/b の形で答えること）',
      answer: "5/2", hint: '行きと帰りを別々に出してから足します。時間は道のり $\div$ 速さです。', difficulty: 4, problem_type: "fill_in",
      solution: '行きは $6 \div 4 = \frac{3}{2}$ 時間、帰りは $6 \div 6 = 1$ 時間。合わせて $\frac{3}{2} + 1 = \frac{5}{2}$ 時間です。往復の平均は時速5kmではない点に注意します。' },
    { question: '家から駅までを分速60mで歩くと、分速90mで歩くより10分多くかかります。家から駅までの道のりは何mですか？（単位はつけず数字だけで答えること）',
      answer: "1800", hint: '道のりを $x$ mとおいて、かかる時間の差が10分になる式を作ります。', difficulty: 5, problem_type: "fill_in",
      solution: '道のりを $x$ mとすると $\frac{x}{60} - \frac{x}{90} = 10$。左辺を通分して $\frac{3x - 2x}{180} = \frac{x}{180}$ なので $\frac{x}{180} = 10$、$x = 1800$ m です。' },
    { question: '兄は分速70m、弟は分速50mで、同じ地点から同時に反対の方向へ歩き出しました。2人が3600mはなれるのは何分後ですか？（単位はつけず数字だけで答えること）',
      answer: "30", hint: '反対の方向なので、1分ごとに2人の速さの合計だけはなれていきます。', difficulty: 5, problem_type: "fill_in",
      solution: '1分間に $70 + 50 = 120$ mずつはなれます。$3600 \div 120 = 30$ 分後です。' }
  ],
  "文字と式（小6）" => [
    { question: '$a = 3$、$b = 5$ のとき、$2a + 3b$ の値を求めなさい。',
      answer: "21", hint: '$a$ と $b$ にそれぞれの数を入れます。', difficulty: 3, problem_type: "fill_in",
      solution: '$2 \times 3 + 3 \times 5 = 6 + 15 = 21$ です。かけ算を先に計算します。' },
    { question: '$a$ 円のノートを3冊買って1000円出したときのおつりを式で表しなさい。（スペースなし）',
      answer: "1000-3a", hint: 'おつりは「出したお金 $-$ 代金」です。', difficulty: 3, problem_type: "fill_in",
      solution: 'ノート3冊の代金は $3a$ 円。おつりは $1000 - 3a$ 円です。$a \times 3$ は $3a$ と数を前に書きます。' },
    { question: '1本 $a$ 円のえんぴつを6本買い、100円の箱に入れてもらいました。代金の合計を式で表しなさい。（スペースなし）',
      answer: "6a+100", hint: 'えんぴつの代金と箱の代金を足します。', difficulty: 4, problem_type: "fill_in",
      solution: 'えんぴつは $a \times 6 = 6a$ 円、箱が $100$ 円なので、合計は $6a + 100$ 円です。' },
    { question: '$a = 8$、$b = 2$ のとき、$\frac{a}{b} + \frac{a - b}{3}$ の値を求めなさい。',
      answer: "6", hint: '分数のまま代入して、それぞれを先に計算します。', difficulty: 5, problem_type: "fill_in",
      solution: '$\frac{8}{2} = 4$、$\frac{8 - 2}{3} = \frac{6}{3} = 2$。足して $4 + 2 = 6$ です。' },
    { question: '1個 $a$ 円のりんごを5個と、1個 $b$ 円のみかんを8個買ったところ、合計から100円引いてもらいました。はらった代金を式で表しなさい。（スペースなし）',
      answer: "5a+8b-100", hint: 'まず引かれる前の合計を作り、最後に100を引きます。', difficulty: 5, problem_type: "fill_in",
      solution: 'りんごは $5a$ 円、みかんは $8b$ 円で、合計 $5a + 8b$ 円。ここから $100$ 円引くので $5a + 8b - 100$ 円です。' }
  ],
  "正の数・負の数" => [
    { question: '$-3^2$ を計算しなさい。',
      answer: "-9", hint: '$-3^2$ は $(-3)^2$ とはちがいます。2乗されているのはどこまででしょう。', difficulty: 3, problem_type: "fill_in",
      solution: '$-3^2$ は $-(3 \times 3) = -9$ です。$(-3)^2 = 9$ とは答えがちがうので、かっこの有無をよく見ます。' },
    { question: '$(-2)^3 \div 4 - (-3)$ を計算しなさい。',
      answer: "1", hint: '累乗 $\rightarrow$ かけ算・わり算 $\rightarrow$ 足し算・引き算 の順です。', difficulty: 4, problem_type: "fill_in",
      solution: '$(-2)^3 = -8$ なので $-8 \div 4 = -2$。$-(-3)$ は $+3$ なので $-2 + 3 = 1$ です。' },
    { question: '$-2^2 - (-3)^2 \times 2$ を計算しなさい。',
      answer: "-22", hint: '$-2^2$ と $(-3)^2$ で、2乗のかかり方がちがいます。', difficulty: 5, problem_type: "fill_in",
      solution: '$-2^2 = -4$、$(-3)^2 = 9$ です。$9 \times 2 = 18$ なので $-4 - 18 = -22$ となります。' },
    { question: '$(-4 + 6) \times (-3)^2 - 5 \times (-2)$ を計算しなさい。',
      answer: "28", hint: 'かっこの中を先に、次に累乗、そのあとかけ算です。', difficulty: 5, problem_type: "fill_in",
      solution: 'かっこの中は $-4 + 6 = 2$、$(-3)^2 = 9$ なので $2 \times 9 = 18$。$5 \times (-2) = -10$ を引くので $18 - (-10) = 28$ です。' }
  ],
  "文字と式" => [
    { question: '$5x - 3 - 2x + 8$ を計算しなさい。（スペースなし、例: 4x+5）',
      answer: "3x+5", hint: '文字の項どうし、数の項どうしをまとめます。', difficulty: 3, problem_type: "fill_in",
      solution: '$5x - 2x = 3x$、$-3 + 8 = 5$ なので $3x + 5$ です。' },
    { question: '$3(2x - 5) - 4(x - 3)$ を計算しなさい。（スペースなし、例: 4x+5）',
      answer: "2x-3", hint: 'かっこを外すとき、うしろの $-4$ は中の両方にかかります。', difficulty: 4, problem_type: "fill_in",
      solution: '$3(2x - 5) = 6x - 15$、$-4(x - 3) = -4x + 12$。合わせて $6x - 4x = 2x$、$-15 + 12 = -3$ なので $2x - 3$ です。' },
    { question: '$a = -2$、$b = 3$ のとき、$a^2 b - a b^2$ の値を求めなさい。',
      answer: "30", hint: '代入するときは $a$ を $(-2)$ とかっこをつけて入れます。', difficulty: 5, problem_type: "fill_in",
      solution: '$a^2 b = (-2)^2 \times 3 = 4 \times 3 = 12$、$a b^2 = (-2) \times 3^2 = -18$。$12 - (-18) = 30$ です。' },
    { question: '$x = -3$ のとき、$-x^2 + 4x + 1$ の値を求めなさい。',
      answer: "-20", hint: '$-x^2$ は $-(x^2)$ です。先に $x^2$ を計算します。', difficulty: 5, problem_type: "fill_in",
      solution: '$x^2 = (-3)^2 = 9$ なので $-x^2 = -9$。$4x = -12$ なので $-9 - 12 + 1 = -20$ です。' }
  ],
  "方程式" => [
    { question: '$6x - 5 = 2x + 19$ を解きなさい。',
      answer: "6", hint: '文字を左、数を右に移項してからまとめます。', difficulty: 3, problem_type: "fill_in",
      solution: '$6x - 2x = 19 + 5$ より $4x = 24$。両辺を $4$ でわって $x = 6$ です。' },
    { question: '$\frac{2x + 1}{3} = \frac{x + 4}{2}$ を解きなさい。',
      answer: "10", hint: '両辺に $6$ をかけて分母をはらいます。', difficulty: 4, problem_type: "fill_in",
      solution: '両辺に $6$ をかけると $2(2x + 1) = 3(x + 4)$。$4x + 2 = 3x + 12$ より $x = 10$ です。' },
    { question: '姉は1500円、妹は900円持っています。2人が同じ金額ずつ使ったところ、姉の残りは妹の残りの3倍になりました。使った金額は何円ですか？（単位はつけず数字だけで答えること）',
      answer: "600", hint: '使った金額を $x$ 円とおいて、残りの関係を式にします。', difficulty: 5, problem_type: "fill_in",
      solution: '使った金額を $x$ 円とすると $1500 - x = 3(900 - x)$。展開して $1500 - x = 2700 - 3x$、$2x = 1200$ より $x = 600$ 円です。' },
    { question: '現在、母は42才、子は12才です。母の年れいが子の年れいの3倍になるのは何年後ですか？（単位はつけず数字だけで答えること）',
      answer: "3", hint: '$x$ 年後には2人とも同じだけ年をとります。', difficulty: 5, problem_type: "fill_in",
      solution: '$x$ 年後を考えると $42 + x = 3(12 + x)$。$42 + x = 36 + 3x$ より $2x = 6$、$x = 3$ 年後です。' }
  ],
  "比例と反比例" => [
    { question: '$y$ が $x$ に比例し、$x = 4$ のとき $y = 12$ です。比例定数を求めなさい。',
      answer: "3", hint: '比例定数は $a = y \div x$ で求まります。', difficulty: 3, problem_type: "fill_in",
      solution: '$a = 12 \div 4 = 3$ です。式にすると $y = 3x$ となります。' },
    { question: '$y$ が $x$ に比例し、$x = -3$ のとき $y = 12$ です。$y = -20$ のときの $x$ の値を求めなさい。',
      answer: "5", hint: '先に比例定数を求めて $y = ax$ の式を作ります。', difficulty: 4, problem_type: "fill_in",
      solution: '$a = 12 \div (-3) = -4$ なので $y = -4x$。$-20 = -4x$ より $x = 5$ です。' },
    { question: '$y$ が $x$ に反比例し、$x = 4$ のとき $y = -6$ です。$x = -3$ のときの $y$ の値を求めなさい。',
      answer: "8", hint: '反比例では $x \times y$ がいつも同じ値になります。', difficulty: 5, problem_type: "fill_in",
      solution: '比例定数は $a = 4 \times (-6) = -24$ なので $y = \frac{-24}{x}$。$x = -3$ を入れて $y = \frac{-24}{-3} = 8$ です。' },
    { question: '歯車Aは歯数24で毎分15回転しています。かみ合っている歯車Bの歯数が18のとき、Bは毎分何回転しますか？（単位はつけず数字だけで答えること）',
      answer: "20", hint: 'かみ合う歯車では「歯数 $\times$ 回転数」が等しくなります（反比例です）。', difficulty: 5, problem_type: "fill_in",
      solution: 'かみ合う歯車では歯数と回転数は反比例します。$24 \times 15 = 18 \times \square$ より $\square = 360 \div 18 = 20$ 回転です。' }
  ]
}

create_problems(advanced_problems_2)

# 選択式の問題。128問中1問しかなく、仕組み（problem_type: "multiple_choice" ＋ choices）が
# ほとんど使われていなかった。
#
# 選択式が向くのは「打てない答え」と「見分け」——式そのものを選ばせる、まちがいを見つける、
# 大小をくらべる、比例か反比例かを答える、など。記述式は答えをキーパッドの17文字で
# 打てる範囲にしばられるが、選択肢にはその制約がない。
#
# 採点は平文比較なので、answer は正解の選択肢の text とぴったり同じにする。
# 選択肢も MathText で描くので $...$ の数式が使える。
#
# 注意: LaTeX を含む文字列は必ずシングルクォート。ダブルクォートだと \frac が
# 改ページ文字、\times がタブに化ける。
choice_problems = {
  "分数のかけ算・わり算" => [
    { question: '$\frac{2}{3} \div \frac{4}{5}$ を計算するとき、はじめに直す式として正しいのはどれですか？',
      answer: '$\frac{2}{3} \times \frac{5}{4}$', hint: 'わり算は、わる数を逆数にしてかけ算に直します。', difficulty: 2, problem_type: "multiple_choice",
      solution: 'わり算はわる数（うしろの分数）を逆数にしてかけ算に直します。$\frac{4}{5}$ の逆数は $\frac{5}{4}$ なので $\frac{2}{3} \times \frac{5}{4}$ です。前の分数はそのままにします。',
      choices: [
        { text: '$\frac{2}{3} \times \frac{5}{4}$', is_correct: true },
        { text: '$\frac{2}{3} \times \frac{4}{5}$', is_correct: false },
        { text: '$\frac{3}{2} \times \frac{4}{5}$', is_correct: false },
        { text: '$\frac{3}{2} \times \frac{5}{4}$', is_correct: false }
      ] },
    { question: '$\frac{3}{5} \times \frac{5}{6}$ の答えはどれですか？',
      answer: '$\frac{1}{2}$', hint: '分子どうし・分母どうしをかけてから約分します。', difficulty: 3, problem_type: "multiple_choice",
      solution: '$\frac{3 \times 5}{5 \times 6} = \frac{15}{30}$ で、約分すると $\frac{1}{2}$ です。分子どうし・分母どうしを「たす」のはまちがいです。',
      choices: [
        { text: '$\frac{8}{11}$', is_correct: false },
        { text: '$\frac{1}{2}$', is_correct: true },
        { text: '$\frac{2}{3}$', is_correct: false },
        { text: '$\frac{5}{11}$', is_correct: false }
      ] },
    { question: '$\square \times \frac{3}{4} = \frac{1}{2}$ の $\square$ にあてはまる数はどれですか？',
      answer: '$\frac{2}{3}$', hint: '$\square = \frac{1}{2} \div \frac{3}{4}$ で求まります。', difficulty: 4, problem_type: "multiple_choice",
      solution: '$\square = \frac{1}{2} \div \frac{3}{4} = \frac{1}{2} \times \frac{4}{3} = \frac{4}{6} = \frac{2}{3}$ です。かけ算のままにすると $\frac{3}{8}$ になってしまいます。',
      choices: [
        { text: '$\frac{3}{8}$', is_correct: false },
        { text: '$\frac{3}{2}$', is_correct: false },
        { text: '$\frac{2}{3}$', is_correct: true },
        { text: '$\frac{8}{3}$', is_correct: false }
      ] }
  ],
  "比と比の値" => [
    { question: '$12 : 18$ を最も簡単な整数の比にしたものはどれですか？',
      answer: '$2 : 3$', hint: '両方を同じ数でわります。$12$ と $18$ の最大公約数は $6$ です。', difficulty: 2, problem_type: "multiple_choice",
      solution: '$12$ と $18$ を最大公約数の $6$ でわると $2 : 3$ です。$6 : 9$ や $4 : 6$ はまだ簡単にできます。',
      choices: [
        { text: '$6 : 9$', is_correct: false },
        { text: '$4 : 6$', is_correct: false },
        { text: '$3 : 2$', is_correct: false },
        { text: '$2 : 3$', is_correct: true }
      ] },
    { question: '比の値が最も大きいのはどれですか？',
      answer: '$7 : 9$', hint: '比の値は $a : b$ を $a \div b$ で計算した数です。', difficulty: 3, problem_type: "multiple_choice",
      solution: '比の値は $a \div b$ です。$3 : 4 = 0.75$、$5 : 8 = 0.625$、$2 : 3 \fallingdotseq 0.67$、$7 : 9 \fallingdotseq 0.78$ なので $7 : 9$ が最大です。分母をそろえてくらべても同じです。',
      choices: [
        { text: '$7 : 9$', is_correct: true },
        { text: '$3 : 4$', is_correct: false },
        { text: '$5 : 8$', is_correct: false },
        { text: '$2 : 3$', is_correct: false }
      ] },
    { question: '$A : B = 3 : 5$ のとき、いつでも正しいといえるのはどれですか？',
      answer: '$A$ は $B$ の $\frac{3}{5}$ 倍', hint: '$A : B = 3 : 5$ なら、$A \div B$ はいくつになるでしょう。', difficulty: 4, problem_type: "multiple_choice",
      solution: '$A : B = 3 : 5$ の比の値は $A \div B = \frac{3}{5}$ なので、$A$ は $B$ の $\frac{3}{5}$ 倍です。差については、$A = 3a$、$B = 5a$ の $a$ が分からないので $2$ とは決まりません。',
      choices: [
        { text: '$A$ は $B$ の $\frac{5}{3}$ 倍', is_correct: false },
        { text: '$A$ は $B$ の $\frac{3}{5}$ 倍', is_correct: true },
        { text: '$B$ は $A$ の $\frac{3}{5}$ 倍', is_correct: false },
        { text: '$B$ と $A$ の差は $2$', is_correct: false }
      ] }
  ],
  "速さ・時間・距離" => [
    { question: '速さを求める式として正しいのはどれですか？',
      answer: '道のり $\div$ 時間', hint: '「1時間あたりに進む道のり」が速さです。', difficulty: 2, problem_type: "multiple_choice",
      solution: '速さは「1時間（1分・1秒）あたりに進む道のり」なので、道のり $\div$ 時間 で求めます。ここから 道のり $=$ 速さ $\times$ 時間、時間 $=$ 道のり $\div$ 速さ も出ます。',
      choices: [
        { text: '道のり $\times$ 時間', is_correct: false },
        { text: '時間 $\div$ 道のり', is_correct: false },
        { text: '道のり $\div$ 時間', is_correct: true },
        { text: '道のり $+$ 時間', is_correct: false }
      ] },
    { question: '次のうち、最も速いのはどれですか？',
      answer: '分速700m', hint: '単位がばらばらなので、秒速か時速にそろえてくらべます。', difficulty: 3, problem_type: "multiple_choice",
      solution: '秒速にそろえます。時速36km $=$ 秒速10m、分速700m $\fallingdotseq$ 秒速11.7m、秒速11m、時速40km $\fallingdotseq$ 秒速11.1m。いちばん速いのは分速700mです。',
      choices: [
        { text: '時速36km', is_correct: false },
        { text: '秒速11m', is_correct: false },
        { text: '時速40km', is_correct: false },
        { text: '分速700m', is_correct: true }
      ] },
    { question: '300mを50秒で走る人の速さと同じものはどれですか？',
      answer: '分速360m', hint: 'まず秒速を求めてから、1分（60秒）で進む道のりを考えます。', difficulty: 4, problem_type: "multiple_choice",
      solution: '$300 \div 50 = 6$ なので秒速6mです。1分は60秒なので $6 \times 60 = 360$、つまり分速360mです。秒速5mや分速300mでは足りません。',
      choices: [
        { text: '分速360m', is_correct: true },
        { text: '秒速5m', is_correct: false },
        { text: '分速300m', is_correct: false },
        { text: '時速18km', is_correct: false }
      ] }
  ],
  "文字と式（小6）" => [
    { question: '$a \times 3 + 5$ を、かけ算の記号を省いて書いたものはどれですか？',
      answer: '$3a + 5$', hint: '文字と数のかけ算は、数を前に書いて $\times$ を省きます。', difficulty: 2, problem_type: "multiple_choice",
      solution: '数を前、文字をうしろに書いて $\times$ を省くので $a \times 3 = 3a$。$+5$ はそのままなので $3a + 5$ です。$a3$ とは書きません。',
      choices: [
        { text: '$a3 + 5$', is_correct: false },
        { text: '$3a + 5$', is_correct: true },
        { text: '$3(a + 5)$', is_correct: false },
        { text: '$a + 35$', is_correct: false }
      ] },
    { question: '1個 $x$ 円のあめを4個買って500円出したときの、おつりを表す式はどれですか？',
      answer: '$500 - 4x$', hint: 'おつりは「出したお金 $-$ 代金」です。代金はいくらでしょう。', difficulty: 3, problem_type: "multiple_choice",
      solution: 'あめ4個の代金は $x \times 4 = 4x$ 円。おつりは出したお金から代金を引くので $500 - 4x$ 円です。引く順番を逆にしないよう気をつけます。',
      choices: [
        { text: '$4x - 500$', is_correct: false },
        { text: '$500 - x + 4$', is_correct: false },
        { text: '$500 - 4x$', is_correct: true },
        { text: '$4(500 - x)$', is_correct: false }
      ] },
    { question: '$x = 3$ のとき、値が最も大きいのはどれですか？',
      answer: '$4x - 2$', hint: 'それぞれに $x = 3$ を入れて、順番に計算してみます。', difficulty: 4, problem_type: "multiple_choice",
      solution: '$x = 3$ を入れると、$4x - 2 = 10$、$2x + 3 = 9$、$x + 6 = 9$、$\frac{x}{3} + 8 = 9$。最も大きいのは $4x - 2$ です。',
      choices: [
        { text: '$2x + 3$', is_correct: false },
        { text: '$x + 6$', is_correct: false },
        { text: '$\frac{x}{3} + 8$', is_correct: false },
        { text: '$4x - 2$', is_correct: true }
      ] }
  ],
  "正の数・負の数" => [
    { question: '絶対値が最も大きいのはどれですか？',
      answer: '$-7$', hint: '絶対値は数直線上で $0$ からどれだけはなれているかです。符号は関係ありません。', difficulty: 2, problem_type: "multiple_choice",
      solution: '絶対値は $0$ からのきょりなので、符号を外した数でくらべます。$|-7| = 7$、$|6| = 6$、$|5| = 5$、$|-3| = 3$ なので $-7$ が最大です。',
      choices: [
        { text: '$-7$', is_correct: true },
        { text: '$5$', is_correct: false },
        { text: '$-3$', is_correct: false },
        { text: '$6$', is_correct: false }
      ] },
    { question: '計算の答えが正の数になるのはどれですか？',
      answer: '$(-2) \times (-3)$', hint: '負の数どうしのかけ算・わり算の符号を思い出します。', difficulty: 3, problem_type: "multiple_choice",
      solution: '負 $\times$ 負 は正なので $(-2) \times (-3) = 6$ です。ほかは $(-2) \times 3 = -6$、$2 \times (-3) = -6$、$(-6) \div 2 = -3$ でどれも負の数になります。',
      choices: [
        { text: '$(-2) \times 3$', is_correct: false },
        { text: '$(-2) \times (-3)$', is_correct: true },
        { text: '$2 \times (-3)$', is_correct: false },
        { text: '$(-6) \div 2$', is_correct: false }
      ] },
    { question: '$(-2)^4$ と $-2^4$ について、正しい説明はどれですか？',
      answer: '$(-2)^4 = 16$、$-2^4 = -16$', hint: 'かっこがあるかどうかで、2乗（4乗）されるものが変わります。', difficulty: 4, problem_type: "multiple_choice",
      solution: '$(-2)^4$ は $-2$ を4回かけるので $16$。$-2^4$ は $-(2 \times 2 \times 2 \times 2) = -16$ です。かっこの有無で答えの符号が変わります。',
      choices: [
        { text: 'どちらも $16$', is_correct: false },
        { text: 'どちらも $-16$', is_correct: false },
        { text: '$(-2)^4 = 16$、$-2^4 = -16$', is_correct: true },
        { text: '$(-2)^4 = -16$、$-2^4 = 16$', is_correct: false }
      ] }
  ],
  "文字と式" => [
    { question: '$x \times x \times y \div 3$ を、記号を省いて書いたものはどれですか？',
      answer: '$\frac{x^2 y}{3}$', hint: '同じ文字のかけ算は累乗で書き、わり算は分数で書きます。', difficulty: 2, problem_type: "multiple_choice",
      solution: '$x \times x = x^2$、$\div 3$ は分母に $3$ を置くので $\frac{x^2 y}{3}$ です。$x \times x$ を $2x$ と書くのはまちがいです。',
      choices: [
        { text: '$\frac{2xy}{3}$', is_correct: false },
        { text: '$3x^2 y$', is_correct: false },
        { text: '$\frac{x^2}{3y}$', is_correct: false },
        { text: '$\frac{x^2 y}{3}$', is_correct: true }
      ] },
    { question: '$-(3x - 2)$ を計算したものはどれですか？',
      answer: '$-3x + 2$', hint: 'かっこの前のマイナスは、中のすべての項の符号を変えます。', difficulty: 3, problem_type: "multiple_choice",
      solution: 'かっこの前の $-$ は $-1$ をかけることなので、中の符号がすべて変わります。$-(3x - 2) = -3x + 2$ です。うしろの $-2$ を $-2$ のままにするのがよくあるまちがいです。',
      choices: [
        { text: '$-3x + 2$', is_correct: true },
        { text: '$-3x - 2$', is_correct: false },
        { text: '$3x - 2$', is_correct: false },
        { text: '$3x + 2$', is_correct: false }
      ] },
    { question: '$x = -2$ のとき、値が $-4$ になるのはどれですか？',
      answer: '$3x + 2$', hint: '代入するときは $x$ を $(-2)$ とかっこをつけて入れます。', difficulty: 4, problem_type: "multiple_choice",
      solution: '$x = -2$ を入れると、$3x + 2 = -6 + 2 = -4$。ほかは $x^2 = 4$、$-2x = 4$、$x - 1 = -3$ です。',
      choices: [
        { text: '$x^2$', is_correct: false },
        { text: '$3x + 2$', is_correct: true },
        { text: '$-2x$', is_correct: false },
        { text: '$x - 1$', is_correct: false }
      ] }
  ],
  "方程式" => [
    { question: '$x + 5 = 12$ を解くとき、最初にすることとして正しいのはどれですか？',
      answer: '両辺から $5$ をひく', hint: '$x$ だけを左に残すには、じゃまな $+5$ をどうすればよいでしょう。', difficulty: 2, problem_type: "multiple_choice",
      solution: '$x$ だけを残したいので、両辺から $5$ をひきます。$x + 5 - 5 = 12 - 5$ となり $x = 7$ です。等式は両辺に同じことをしても成り立ちます。',
      choices: [
        { text: '両辺に $5$ をたす', is_correct: false },
        { text: '両辺を $5$ でわる', is_correct: false },
        { text: '両辺から $5$ をひく', is_correct: true },
        { text: '両辺に $5$ をかける', is_correct: false }
      ] },
    { question: '次のうち、$x = 3$ が解になる方程式はどれですか？',
      answer: '$2x - 1 = 5$', hint: 'それぞれの式に $x = 3$ を入れて、左辺と右辺が等しくなるか確かめます。', difficulty: 3, problem_type: "multiple_choice",
      solution: '$x = 3$ を入れると $2x - 1 = 6 - 1 = 5$ で右辺と一致します。ほかは $x + 4 = 6$ が $x = 2$、$3x = 12$ が $x = 4$、$5 - x = 3$ が $x = 2$ です。',
      choices: [
        { text: '$x + 4 = 6$', is_correct: false },
        { text: '$3x = 12$', is_correct: false },
        { text: '$5 - x = 3$', is_correct: false },
        { text: '$2x - 1 = 5$', is_correct: true }
      ] },
    { question: '1本 $x$ 円のジュースを4本買って1000円出したら、おつりは200円でした。この場面を表す方程式はどれですか？',
      answer: '$1000 - 4x = 200$', hint: '「出したお金 $-$ 代金 $=$ おつり」を式にします。', difficulty: 4, problem_type: "multiple_choice",
      solution: '代金は $4x$ 円なので、おつりは $1000 - 4x$ 円。これが200円なので $1000 - 4x = 200$ です。解くと $x = 200$ になります。',
      choices: [
        { text: '$1000 - 4x = 200$', is_correct: true },
        { text: '$4x - 1000 = 200$', is_correct: false },
        { text: '$4(x - 1000) = 200$', is_correct: false },
        { text: '$1000 - x = 200 \times 4$', is_correct: false }
      ] }
  ],
  "比例と反比例" => [
    { question: '$y$ が $x$ に反比例するのはどれですか？',
      answer: '$y = \frac{6}{x}$', hint: '反比例は $y = \frac{a}{x}$ の形です。', difficulty: 2, problem_type: "multiple_choice",
      solution: '反比例は $y = \frac{a}{x}$ の形なので $y = \frac{6}{x}$ です。$y = 6x$ は比例、$y = x + 6$ と $y = 6 - x$ はどちらでもありません。',
      choices: [
        { text: '$y = 6x$', is_correct: false },
        { text: '$y = \frac{6}{x}$', is_correct: true },
        { text: '$y = x + 6$', is_correct: false },
        { text: '$y = 6 - x$', is_correct: false }
      ] },
    { question: '$y$ が $x$ に比例するとき、正しい説明はどれですか？',
      answer: '$x$ が2倍になると $y$ も2倍になる', hint: '比例は $y = ax$ の形です。$x$ を2倍にすると $y$ はどうなるでしょう。', difficulty: 3, problem_type: "multiple_choice",
      solution: '比例は $y = ax$ なので、$x$ を2倍にすると $y$ も2倍になります。「$x \times y$ がいつも同じ」は反比例の性質です。',
      choices: [
        { text: '$x$ が2倍になると $y$ は $\frac{1}{2}$ 倍になる', is_correct: false },
        { text: '$x$ が増えても $y$ は変わらない', is_correct: false },
        { text: '$x$ が2倍になると $y$ も2倍になる', is_correct: true },
        { text: '$x \times y$ がいつも同じ値になる', is_correct: false }
      ] },
    { question: '$y$ が $x$ に反比例し、$x = 2$ のとき $y = 12$ です。この関係を表す式はどれですか？',
      answer: '$y = \frac{24}{x}$', hint: '反比例の比例定数は $x \times y$ で求まります。', difficulty: 4, problem_type: "multiple_choice",
      solution: '比例定数は $a = x \times y = 2 \times 12 = 24$ なので $y = \frac{24}{x}$ です。$a = y \div x$ としてしまうと比例の式になってしまいます。',
      choices: [
        { text: '$y = 6x$', is_correct: false },
        { text: '$y = \frac{6}{x}$', is_correct: false },
        { text: '$y = 24x$', is_correct: false },
        { text: '$y = \frac{24}{x}$', is_correct: true }
      ] }
  ]
}

create_problems(choice_problems)

# ===== 国語（小学6年生）=====
#
# ランクは別のまとまりにする。算数・数学とは積み上げが別系統なので、同じまとまりに
# 入れると「国語をやった分で数学のランクが上がる」ことになってしまう。
japanese_group = SubjectGroup.find_or_create_by!(name: "国語") { |g| g.display_order = 1 }
japanese = Subject.find_or_create_by!(name: "国語") { |s| s.subject_group = japanese_group }
japanese.update!(subject_group: japanese_group) if japanese.subject_group_id.nil?

# 国語の答えは漢字やひらがなで、キーパッド（AnswerInput の KEYPAD_ROWS）では打てない。
# そのため**全問を選択式**にしている。打てない答えは選択式にする、という既存の方針どおり。
units_japanese = [
  { title: "漢字の読み書き",   description: "小6で習う漢字の読み・送りがな・同音異義語",           display_order: 5,
    stat_types: -> { [stat_vocab, stat_reading] } },
  { title: "ことばの意味",     description: "慣用句・ことわざ・四字熟語の意味と使い分け",         display_order: 6,
    stat_types: -> { [stat_vocab] } },
  { title: "説明文の読み取り", description: "接続語・指示語をたどって、筆者の言いたいことをつかむ", display_order: 7,
    stat_types: -> { [stat_reading, stat_logic] } }
]

units_japanese.each do |ud|
  unit = Unit.find_or_create_by!(title: ud[:title], grade: grade6) do |u|
    u.subject = japanese
    u.description = ud[:description]
    u.display_order = ud[:display_order]
  end
  ud[:stat_types].call.each { |st| UnitStatType.find_or_create_by!(unit: unit, stat_type: st) }
end

# 国語の問題。全問が選択式（答えが漢字・ひらがなでキーパッドから打てないため）。
# answer は正解の選択肢の文字列とぴったり同じにすること。
japanese_problems = {
  "漢字の読み書き" => [
    { question: "「厳しい」の読み方はどれですか？",
      answer: "きびしい", hint: "「げんかく（厳格）」の「厳」です。", difficulty: 1, problem_type: "multiple_choice",
      solution: "「厳しい」は「きびしい」と読みます。音読みは「ゲン」で、「厳格」「厳重」などに使います。",
      choices: [
        { text: "きびしい", is_correct: true },
        { text: "はげしい", is_correct: false },
        { text: "くるしい", is_correct: false },
        { text: "さびしい", is_correct: false }
      ] },
    { question: "「幼い」の読み方はどれですか？",
      answer: "おさない", hint: "「幼稚園（ようちえん）」の「幼」です。", difficulty: 1, problem_type: "multiple_choice",
      solution: "「幼い」は「おさない」と読みます。年れいが小さいことを表します。音読みは「ヨウ」で「幼児」「幼虫」などに使います。",
      choices: [
        { text: "わかい", is_correct: false },
        { text: "おさない", is_correct: true },
        { text: "ちいさい", is_correct: false },
        { text: "あさい", is_correct: false }
      ] },
    { question: "「胸」の音読みはどれですか？",
      answer: "キョウ", hint: "「胸囲（きょうい）」ということばを思い出しましょう。", difficulty: 2, problem_type: "multiple_choice",
      solution: "「胸」の音読みは「キョウ」で、「胸囲」「度胸」などに使います。訓読みは「むね」です。",
      choices: [
        { text: "ムネ", is_correct: false },
        { text: "ケイ", is_correct: false },
        { text: "キョウ", is_correct: true },
        { text: "コウ", is_correct: false }
      ] },
    { question: "「あたたかい」を漢字と送りがなで正しく書いたものはどれですか？（気温のとき）",
      answer: "暖かい", hint: "送りがなは、変わる部分から送ります。「あたたかろう」「あたたかった」と変わるのはどこでしょう。", difficulty: 2, problem_type: "multiple_choice",
      solution: "気温には「暖かい」を使い、送りがなは「かい」です。「暖」までが変わらない部分なので、そこから送ります。なお心や食べ物には「温かい」を使います。",
      choices: [
        { text: "暖い", is_correct: false },
        { text: "暖たかい", is_correct: false },
        { text: "暖かたい", is_correct: false },
        { text: "暖かい", is_correct: true }
      ] },
    { question: "「会社につとめる」の「つとめる」に合う漢字はどれですか？",
      answer: "勤める", hint: "「勤務（きんむ）」ということばを思い出しましょう。", difficulty: 3, problem_type: "multiple_choice",
      solution: "会社ではたらくのは「勤める」です。「努める」は努力すること、「務める」は役目を引き受けること（司会を務める）で、使い分けます。",
      choices: [
        { text: "勤める", is_correct: true },
        { text: "努める", is_correct: false },
        { text: "務める", is_correct: false },
        { text: "勉める", is_correct: false }
      ] },
    { question: "「読書」と同じ組み立ての熟語はどれですか？（下の字が上の字の目的や対象になっているもの）",
      answer: "登山", hint: "「読書」は「書を読む」と、下から上に返って読めます。", difficulty: 3, problem_type: "multiple_choice",
      solution: "「読書」は「書を読む」と読める組み立てです。「登山」も「山に登る」と読めるので同じ形です。「親友」は上が下を修飾、「高低」は反対の意味の組み合わせ、「年少」は主語と述語の関係です。",
      choices: [
        { text: "親友", is_correct: false },
        { text: "登山", is_correct: true },
        { text: "高低", is_correct: false },
        { text: "年少", is_correct: false }
      ] },
    { question: "「複雑」の反対の意味を表すことばはどれですか？",
      answer: "単純", hint: "「入り組んでいる」の反対は「こみいっていない」です。", difficulty: 3, problem_type: "multiple_choice",
      solution: "「複雑」の対義語は「単純」です。「簡易」「容易」「明白」はどれも似た感じがしますが、「複雑」とちょうど反対の組みになるのは「単純」です。",
      choices: [
        { text: "簡易", is_correct: false },
        { text: "容易", is_correct: false },
        { text: "単純", is_correct: true },
        { text: "明白", is_correct: false }
      ] },
    { question: "「実験のカテイを記録する」の「カテイ」に合う漢字はどれですか？",
      answer: "過程", hint: "「とちゅうの道すじ」という意味です。", difficulty: 4, problem_type: "multiple_choice",
      solution: "とちゅうの道すじを表すのは「過程」です。「課程」は学校で学ぶ内容のまとまり、「仮定」はかりに決めること、「家庭」は家族の集まりを指します。",
      choices: [
        { text: "家庭", is_correct: false },
        { text: "課程", is_correct: false },
        { text: "仮定", is_correct: false },
        { text: "過程", is_correct: true }
      ] },
    { question: "「無意識」と同じ組み立ての三字熟語はどれですか？",
      answer: "未完成", hint: "「無」は下の二字を打ち消しています。同じはたらきの字が上についているのはどれでしょう。", difficulty: 4, problem_type: "multiple_choice",
      solution: "「無意識」は打ち消しの「無」が下の二字についた形です。「未完成」も「未」が打ち消しているので同じ形です。「衣食住」「松竹梅」「都道府県」は同じ仲間のことばを並べた形です。",
      choices: [
        { text: "衣食住", is_correct: false },
        { text: "未完成", is_correct: true },
        { text: "松竹梅", is_correct: false },
        { text: "都道府県", is_correct: false }
      ] },
    { question: "送りがなが正しいものはどれですか？（「こころざす」）",
      answer: "志す", hint: "「志」の一字で「こころざ」まで読みます。", difficulty: 4, problem_type: "multiple_choice",
      solution: "「志す」が正しい書き方です。「志」だけで「こころざ」と読み、変化する「す」だけを送ります。",
      choices: [
        { text: "志ざす", is_correct: false },
        { text: "志こころざす", is_correct: false },
        { text: "志す", is_correct: true },
        { text: "志しす", is_correct: false }
      ] },
    { question: "「生」の読み方が、ほかの三つとちがうものはどれですか？",
      answer: "生糸", hint: "音読みか訓読みかで分けてみましょう。", difficulty: 5, problem_type: "multiple_choice",
      solution: "「生物」「生死」「生活」はどれも音読みで「セイ」と読みます。「生糸」だけは訓読みで「きいと」と読みます。「生」は読み方の多い漢字なので、熟語ごとに覚えます。",
      choices: [
        { text: "生物", is_correct: false },
        { text: "生死", is_correct: false },
        { text: "生糸", is_correct: true },
        { text: "生活", is_correct: false }
      ] },
    { question: "上の字が下の字をくわしく説明している熟語はどれですか？",
      answer: "青空", hint: "「〜な○○」と説明する形になっているものをさがします。", difficulty: 5, problem_type: "multiple_choice",
      solution: "「青空」は「青い空」で、上の字が下の字をくわしくしています。「登山」は「山に登る」、「高低」は反対の意味の組み合わせ、「地震」は「地が震える」で主語と述語の関係です。",
      choices: [
        { text: "青空", is_correct: true },
        { text: "登山", is_correct: false },
        { text: "高低", is_correct: false },
        { text: "地震", is_correct: false }
      ] },
    { question: "「委員長にスイセンされる」の「スイセン」に合う漢字はどれですか？",
      answer: "推薦", hint: "「よい人としてすすめる」という意味です。", difficulty: 5, problem_type: "multiple_choice",
      solution: "人をすすめるのは「推薦」です。「推選」は選び出すこと、「水洗」は水で洗うこと、「吹奏」は楽器をふいて演奏することで、どれも意味がちがいます。",
      choices: [
        { text: "推選", is_correct: false },
        { text: "水洗", is_correct: false },
        { text: "吹奏", is_correct: false },
        { text: "推薦", is_correct: true }
      ] }
  ],
  "ことばの意味" => [
    { question: "「油を売る」の意味はどれですか？",
      answer: "むだ話をして、仕事をなまける", hint: "昔、油売りが客と長話をしたことからできたことばです。", difficulty: 1, problem_type: "multiple_choice",
      solution: "「油を売る」は、むだ話などをして仕事をなまけることです。昔の油売りが客と長話をしながら売っていたことからきています。",
      choices: [
        { text: "むだ話をして、仕事をなまける", is_correct: true },
        { text: "商売がうまくいく", is_correct: false },
        { text: "とても急いでいる", is_correct: false },
        { text: "人にお世辞を言う", is_correct: false }
      ] },
    { question: "「猫の手も借りたい」の意味はどれですか？",
      answer: "とてもいそがしい", hint: "役に立ちそうにない猫の手まで借りたい、という気持ちです。", difficulty: 1, problem_type: "multiple_choice",
      solution: "「猫の手も借りたい」は、役に立ちそうにない猫の手さえ借りたくなるほど、とてもいそがしいことを表します。",
      choices: [
        { text: "動物が好きだ", is_correct: false },
        { text: "とてもいそがしい", is_correct: true },
        { text: "人手が足りていて楽だ", is_correct: false },
        { text: "こっそりと何かをする", is_correct: false }
      ] },
    { question: "「後の祭り」の意味はどれですか？",
      answer: "時期がすぎて、今さらどうにもならない", hint: "お祭りが終わってから出かけても、もう見られません。", difficulty: 2, problem_type: "multiple_choice",
      solution: "「後の祭り」は、時期がすぎてしまって今さらどうにもならないこと、つまり手おくれを表します。祭りが終わったあとに行っても見られないことからきています。",
      choices: [
        { text: "楽しいことが続く", is_correct: false },
        { text: "みんなで祝う", is_correct: false },
        { text: "時期がすぎて、今さらどうにもならない", is_correct: true },
        { text: "順番が回ってくる", is_correct: false }
      ] },
    { question: "「耳が痛い」の意味はどれですか？",
      answer: "自分の弱点を言われて、聞くのがつらい", hint: "本当に耳が痛むわけではありません。", difficulty: 2, problem_type: "multiple_choice",
      solution: "「耳が痛い」は、自分の弱点や欠点を言われて、聞くのがつらいという意味です。体のようすではなく気持ちを表す慣用句です。",
      choices: [
        { text: "大きな音がうるさい", is_correct: false },
        { text: "自分の弱点を言われて、聞くのがつらい", is_correct: true },
        { text: "同じ話を何度も聞かされる", is_correct: false },
        { text: "よい知らせを聞いてうれしい", is_correct: false }
      ] },
    { question: "「情けは人のためならず」の意味はどれですか？",
      answer: "人に親切にすると、めぐりめぐって自分に返ってくる", hint: "「ためならず」は「その人のためにならない」ではありません。", difficulty: 3, problem_type: "multiple_choice",
      solution: "「情けは人のためならず」は、人にかけた親切はめぐりめぐって自分に返ってくる、という意味です。「親切はその人のためにならない」と取りちがえやすいことわざの代表です。",
      choices: [
        { text: "親切にすると、その人のためにならない", is_correct: false },
        { text: "人に親切にすると、めぐりめぐって自分に返ってくる", is_correct: true },
        { text: "人の助けをあてにしてはいけない", is_correct: false },
        { text: "情けをかけるのはむだである", is_correct: false }
      ] },
    { question: "「五十歩百歩」と似た意味のことわざはどれですか？",
      answer: "どんぐりの背くらべ", hint: "どちらも「たいしたちがいがない」という意味です。", difficulty: 3, problem_type: "multiple_choice",
      solution: "「五十歩百歩」は、少しのちがいはあっても本質的には同じだという意味です。「どんぐりの背くらべ」も、どれも似たようなもので大きな差がないことを表します。",
      choices: [
        { text: "急がば回れ", is_correct: false },
        { text: "石の上にも三年", is_correct: false },
        { text: "どんぐりの背くらべ", is_correct: true },
        { text: "ちりも積もれば山となる", is_correct: false }
      ] },
    { question: "「愛想がつきる」の意味はどれですか？",
      answer: "あきれて、見はなしたい気持ちになる", hint: "よい意味では使いません。", difficulty: 3, problem_type: "multiple_choice",
      solution: "「愛想がつきる」は、相手にあきれてしまって、もう付き合いたくないという気持ちになることです。",
      choices: [
        { text: "あきれて、見はなしたい気持ちになる", is_correct: true },
        { text: "うれしくてたまらない", is_correct: false },
        { text: "とても親しくなる", is_correct: false },
        { text: "遠慮がなくなる", is_correct: false }
      ] },
    { question: "「手を焼く」の意味はどれですか？",
      answer: "あつかいに困る", hint: "料理で手をやけどする、という意味ではありません。", difficulty: 4, problem_type: "multiple_choice",
      solution: "「手を焼く」は、うまく処理できずにあつかいに困ることです。「弟のいたずらに手を焼く」のように使います。",
      choices: [
        { text: "料理が上手になる", is_correct: false },
        { text: "あつかいに困る", is_correct: true },
        { text: "仕事を手伝う", is_correct: false },
        { text: "力をつくして働く", is_correct: false }
      ] },
    { question: "「気が置けない友人」とは、どんな友人ですか？",
      answer: "遠慮をしなくてよい、打ちとけた友人", hint: "「油断できない」という意味で使うのはまちがいです。", difficulty: 4, problem_type: "multiple_choice",
      solution: "「気が置けない」は、気をつかう必要がない、つまり遠慮なく付き合えるという意味です。「油断できない」と反対の意味で取りちがえる人が多いことばです。",
      choices: [
        { text: "油断できない、信用しにくい友人", is_correct: false },
        { text: "いつもけんかをする友人", is_correct: false },
        { text: "遠慮をしなくてよい、打ちとけた友人", is_correct: true },
        { text: "めったに会えない友人", is_correct: false }
      ] },
    { question: "「一石二鳥」と同じ意味の四字熟語はどれですか？",
      answer: "一挙両得", hint: "一つのことで二つの得をする、という意味です。", difficulty: 4, problem_type: "multiple_choice",
      solution: "「一石二鳥」は一つの行いで二つの利益を得ることです。「一挙両得」も同じ意味です。「一朝一夕」はごく短い時間、「一長一短」は長所も短所もあること、「一進一退」はよくなったり悪くなったりすることです。",
      choices: [
        { text: "一朝一夕", is_correct: false },
        { text: "一長一短", is_correct: false },
        { text: "一進一退", is_correct: false },
        { text: "一挙両得", is_correct: true }
      ] },
    { question: "「手ごたえがなく、はりあいがない」という意味を表すのはどれですか？",
      answer: "ぬかにくぎ", hint: "やわらかいものにくぎを打っても、きき目がありません。", difficulty: 5, problem_type: "multiple_choice",
      solution: "「ぬかにくぎ」は、やわらかいぬかにくぎを打つように、いくらはたらきかけても手ごたえがないことです。「のれんに腕おし」も同じ意味です。",
      choices: [
        { text: "ぬかにくぎ", is_correct: true },
        { text: "火に油をそそぐ", is_correct: false },
        { text: "石橋をたたいて渡る", is_correct: false },
        { text: "地に足がつく", is_correct: false }
      ] },
    { question: "「（　）を長くして待つ」の（　）に入る、体を表すことばはどれですか？",
      answer: "首", hint: "早く来ないかと、のび上がって待つようすです。", difficulty: 5, problem_type: "multiple_choice",
      solution: "「首を長くして待つ」で、今か今かと待ちこがれるようすを表します。のび上がって遠くを見ようとする姿からきています。",
      choices: [
        { text: "目", is_correct: false },
        { text: "首", is_correct: true },
        { text: "手", is_correct: false },
        { text: "耳", is_correct: false }
      ] },
    { question: "「以心（　）心」の（　）に入る漢字はどれですか？",
      answer: "伝", hint: "ことばにしなくても気持ちが通じることを表す四字熟語です。", difficulty: 5, problem_type: "multiple_choice",
      solution: "「以心伝心」で、ことばにしなくてもたがいの気持ちが通じ合うことを表します。「心をもって心に伝える」という組み立てです。",
      choices: [
        { text: "電", is_correct: false },
        { text: "転", is_correct: false },
        { text: "伝", is_correct: true },
        { text: "点", is_correct: false }
      ] }
  ],
  "説明文の読み取り" => [
    { question: "「朝から雨がふっていた。（　）、遠足は中止になった。」の（　）に入ることばはどれですか？",
      answer: "だから", hint: "前の文が理由、あとの文がその結果になっています。", difficulty: 1, problem_type: "multiple_choice",
      solution: "前の「雨がふっていた」が理由で、あとの「中止になった」がその結果です。理由と結果をつなぐのは「だから」です。",
      choices: [
        { text: "だから", is_correct: true },
        { text: "しかし", is_correct: false },
        { text: "たとえば", is_correct: false },
        { text: "または", is_correct: false }
      ] },
    { question: "「机の上に一冊の本がある。それは兄のものだ。」の「それ」が指しているものはどれですか？",
      answer: "本", hint: "指示語の指す内容は、たいてい前の文にあります。", difficulty: 1, problem_type: "multiple_choice",
      solution: "「それ」を「本」に置きかえると「本は兄のものだ」となり、意味が通ります。指示語が指すものは、前の文からさがして入れかえてみると確かめられます。",
      choices: [
        { text: "机", is_correct: false },
        { text: "上", is_correct: false },
        { text: "本", is_correct: true },
        { text: "兄", is_correct: false }
      ] },
    { question: "「このかばんは値段が高い。（　）、とてもじょうぶだ。」の（　）に入ることばはどれですか？",
      answer: "しかし", hint: "前の内容とあとの内容が、反対の向きになっています。", difficulty: 2, problem_type: "multiple_choice",
      solution: "「値段が高い」は短所、「じょうぶだ」は長所で、向きが反対です。反対の内容をつなぐのは「しかし」です。",
      choices: [
        { text: "そのうえ", is_correct: false },
        { text: "しかし", is_correct: true },
        { text: "だから", is_correct: false },
        { text: "つまり", is_correct: false }
      ] },
    { question: "段落が「たとえば」ということばで始まっているとき、その段落のはたらきはどれですか？",
      answer: "前に述べたことの具体例をあげる", hint: "「たとえば」のあとには、いつも何が続くでしょう。", difficulty: 2, problem_type: "multiple_choice",
      solution: "「たとえば」は具体例を示すことばです。前の段落で述べた考えを、実際の例で分かりやすくする役目をしています。",
      choices: [
        { text: "前に述べたことを打ち消す", is_correct: false },
        { text: "前に述べたことの具体例をあげる", is_correct: true },
        { text: "話題をまったく別のものに変える", is_correct: false },
        { text: "文章全体をまとめる", is_correct: false }
      ] },
    { question: "次の文章を読んで答えなさい。「植物は動くことができない。そのため、種を遠くへ運ぶしくみを持っている。風に飛ばされるもの、動物の毛につくもの、実を食べてもらうもの。どれも、自分では動けないという弱点をおぎなうくふうである。」——この文章で筆者がいちばん言いたいことはどれですか？",
      answer: "植物は動けない弱点を、種を運ぶくふうでおぎなっている", hint: "最初の文と最後の文をつなげて読んでみましょう。", difficulty: 3, problem_type: "multiple_choice",
      solution: "最初に「動くことができない」という弱点を示し、最後に「弱点をおぎなうくふう」とまとめています。とちゅうの三つの例は、そのくふうの具体例です。",
      choices: [
        { text: "植物には風に飛ばされる種が多い", is_correct: false },
        { text: "動物は植物の種を運ぶ役目をしている", is_correct: false },
        { text: "植物は動けない弱点を、種を運ぶくふうでおぎなっている", is_correct: true },
        { text: "植物は動物よりもすぐれている", is_correct: false }
      ] },
    { question: "次の文章の「この方法」が指しているものはどれですか？「氷を長持ちさせたいときは、新聞紙で包んでからクーラーボックスに入れるとよい。この方法なら、ふつうより二倍ほど長くもつ。」",
      answer: "新聞紙で包んでからクーラーボックスに入れること", hint: "指示語のところに、選んだ内容をそのまま入れて読んでみましょう。", difficulty: 3, problem_type: "multiple_choice",
      solution: "「この方法」に「新聞紙で包んでからクーラーボックスに入れること」を入れると意味が通ります。指示語は直前の内容を指すことが多く、入れかえて確かめるのが確実です。",
      choices: [
        { text: "氷を長持ちさせたいと思うこと", is_correct: false },
        { text: "新聞紙で包んでからクーラーボックスに入れること", is_correct: true },
        { text: "クーラーボックスを二倍の大きさにすること", is_correct: false },
        { text: "氷をふつうより多く用意すること", is_correct: false }
      ] },
    { question: "次の文章で、筆者が「早ね早おき」をすすめる理由はどれですか？「体には、朝の光を浴びると目が覚め、暗くなると眠くなるリズムがそなわっている。夜おそくまで明かりの下にいると、このリズムがくるってしまう。だから早ねをすすめたい。」",
      answer: "夜ふかしをすると、体のリズムがくるってしまうから", hint: "「だから」の直前に理由が書かれています。", difficulty: 3, problem_type: "multiple_choice",
      solution: "「だから早ねをすすめたい」の直前に「このリズムがくるってしまう」とあります。理由を問われたら、結論の直前をさがすのが基本です。",
      choices: [
        { text: "朝の光を浴びると気持ちがよいから", is_correct: false },
        { text: "夜ふかしをすると、体のリズムがくるってしまうから", is_correct: true },
        { text: "早おきをすると勉強がはかどるから", is_correct: false },
        { text: "暗いところにいると目が悪くなるから", is_correct: false }
      ] },
    { question: "次の文章の要旨として最も適切なものはどれですか？「道具は、人の力を大きくするために生まれた。てこは小さな力を大きな力に変え、車輪は重い物を軽く運ばせる。だが道具は、使う人の考えまで大きくしてくれるわけではない。何のために使うのかは、いつも人が決めなければならない。」",
      answer: "道具は力を大きくするが、使い道を決めるのは人である", hint: "「だが」のあとに、筆者がいちばん言いたいことが来ています。", difficulty: 4, problem_type: "multiple_choice",
      solution: "前半で道具の便利さを認めたうえで、「だが」で向きを変え、「使い道は人が決める」と述べています。逆接のあとに筆者の主張が来る、という型です。",
      choices: [
        { text: "てこや車輪は、とても役に立つ発明である", is_correct: false },
        { text: "道具は人の力を大きくするので、たくさん使うべきだ", is_correct: false },
        { text: "道具にたよりすぎると、人の力は弱くなる", is_correct: false },
        { text: "道具は力を大きくするが、使い道を決めるのは人である", is_correct: true }
      ] },
    { question: "次の文章で、筆者は二つのものを何のためにくらべていますか？「日本の家は木でつくられることが多く、ヨーロッパでは石が多い。日本は湿気が多く、木は湿気を吸ってくれる。ヨーロッパは乾そうしていて、石でも住みやすい。家の材料は、その土地の気候が決めてきたのである。」",
      answer: "家の材料が、その土地の気候によって決まることを示すため", hint: "最後の一文が、くらべた結果のまとめになっています。", difficulty: 4, problem_type: "multiple_choice",
      solution: "日本とヨーロッパをくらべたうえで、最後に「その土地の気候が決めてきた」とまとめています。二つを並べるのは、共通するきまりを示すためです。",
      choices: [
        { text: "日本の家のほうがすぐれていることを示すため", is_correct: false },
        { text: "家の材料が、その土地の気候によって決まることを示すため", is_correct: true },
        { text: "木と石のどちらが丈夫かをくらべるため", is_correct: false },
        { text: "ヨーロッパの気候を説明するため", is_correct: false }
      ] },
    { question: "「この魚は深い海にすんでいる。（　）、水族館で見られることはめったにない。」の（　）に入ることばはどれですか？",
      answer: "そのため", hint: "前が理由で、あとがその結果になっているかを確かめましょう。", difficulty: 4, problem_type: "multiple_choice",
      solution: "「深い海にすんでいる」が理由で、「めったに見られない」がその結果です。理由と結果をつなぐ「そのため」が入ります。「ところが」は逆接、「また」は付け加え、「つまり」は言いかえです。",
      choices: [
        { text: "ところが", is_correct: false },
        { text: "また", is_correct: false },
        { text: "そのため", is_correct: true },
        { text: "つまり", is_correct: false }
      ] },
    { question: "次の文章で、筆者の考えとして最も適切なものはどれですか？「失敗すると、人はその原因をさがす。原因が分かれば、次は同じところでつまずかない。つまり失敗は、次に進むための手がかりを残してくれる。ただし、原因をさがさずに終わらせてしまえば、それはただの失敗のままである。」",
      answer: "失敗は、原因をさがして初めて次に生きる", hint: "「ただし」のあとの条件まで読んで、全体をまとめましょう。", difficulty: 5, problem_type: "multiple_choice",
      solution: "「失敗は手がかりを残す」と述べたあと、「ただし、原因をさがさずに終わらせれば、ただの失敗のまま」と条件をつけています。条件まで含めると「原因をさがして初めて次に生きる」となります。",
      choices: [
        { text: "失敗は、原因をさがして初めて次に生きる", is_correct: true },
        { text: "失敗はしないほうがよい", is_correct: false },
        { text: "失敗はいつでも成功のもとになる", is_correct: false },
        { text: "原因をさがすことは、なかなかむずかしい", is_correct: false }
      ] },
    { question: "次の文章の組み立てとして正しいものはどれですか？「【1】時計は、時間を計るための道具である。【2】砂時計は砂の落ちる量で計った。【3】水時計は水の減り方で計った。【4】どちらも、少しずつ変わっていくものを使って時間を表している。」",
      answer: "1で話題を示し、2と3で例をあげ、4でまとめている", hint: "それぞれの段落が、話題・例・まとめのどれにあたるかを考えます。", difficulty: 5, problem_type: "multiple_choice",
      solution: "【1】で「時計とは何か」という話題を示し、【2】【3】で具体例を二つあげ、【4】の「どちらも」で共通点をまとめています。話題→例→まとめは説明文の基本の型です。",
      choices: [
        { text: "1で問いを出し、2から4で順に答えている", is_correct: false },
        { text: "1と2で反対の意見を並べ、3と4で選んでいる", is_correct: false },
        { text: "1で話題を示し、2と3で例をあげ、4でまとめている", is_correct: true },
        { text: "1から3まで理由を並べ、4で新しい話題に移っている", is_correct: false }
      ] },
    { question: "次の文章で、——の「それ」が指しているものはどれですか？「動物園のライオンは、野生のライオンより長生きすることが多い。えさの心配がなく、けがをしても手当てを受けられるからだ。しかし、それと引きかえに、広い場所を走り回る自由は失われている。」",
      answer: "えさの心配がなく、手当ても受けられるという安全さ", hint: "「引きかえに」とあるので、何かを差し出して自由を失った、という関係です。", difficulty: 5, problem_type: "multiple_choice",
      solution: "「それと引きかえに自由が失われる」という形なので、「それ」は自由と交換されたもの、つまり前の文の「えさの心配がなく手当ても受けられる」という安全さを指します。",
      choices: [
        { text: "野生のライオンであること", is_correct: false },
        { text: "長生きすること自体", is_correct: false },
        { text: "動物園という建物", is_correct: false },
        { text: "えさの心配がなく、手当ても受けられるという安全さ", is_correct: true }
      ] }
  ]
}

create_problems(japanese_problems)

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
  "漢字の読み書き" => <<~'MD',
    ## 漢字の読み書き

    漢字は「読めればいい」ものではありません。**同じ読み方でちがう漢字**がたくさんあるので、意味で選べるようになると、文章がぐっと正確に書けるようになります。

    ### 音読みと訓読み
    漢字には二とおりの読み方があります。

    - **音読み** … 中国から来た読み方。カタカナで書くことが多い（胸 → キョウ）
    - **訓読み** … 日本のことばをあてた読み方。それだけで意味が分かる（胸 → むね）

    熟語はふつう音読みどうし、訓読みどうしで組み合わさります。「生糸（きいと）」のように訓読みで読む熟語もあるので、熟語ごとに覚えるのが確実です。

    ### 送りがなのきまり
    送りがなは、**形が変わる部分から送る**のが基本です。

    - あたたかい → あたたかろう・あたたかった … 変わるのは「かい」の部分 → **暖かい**
    - こころざす → こころざそう・こころざした … 変わるのは「す」の部分 → **志す**

    ### 同じ読みで意味がちがう漢字
    文の意味から選びます。

    | 読み | 漢字 | 意味 |
    |------|------|------|
    | つとめる | 勤める | 会社などではたらく |
    | | 努める | 努力する |
    | | 務める | 役目を引き受ける |
    | カテイ | 過程 | とちゅうの道すじ |
    | | 課程 | 学校で学ぶ内容のまとまり |
    | | 仮定 | かりに決めること |

    ### 熟語の組み立て
    二字熟語は、組み立てで四つに分けられます。

    1. 似た意味を重ねる（**豊富**）
    2. 反対の意味を組み合わせる（**高低**）
    3. 上が下をくわしくする（**青空** ＝ 青い空）
    4. 下が上の目的や対象になる（**読書** ＝ 書を読む）

    「読書」の仲間かどうかは、**下から上へ返って読めるか**で見分けられます。

    ### よくあるまちがい
    - 「志ざす」と送ってしまう … 「志」だけで「こころざ」と読みます
    - 「暖かい」と「温かい」の混同 … 気温は「暖」、心や飲み物は「温」
  MD
  "ことばの意味" => <<~'MD',
    ## ことばの意味（慣用句・ことわざ・四字熟語）

    慣用句やことわざは、**ことばをそのままの意味で足し算しても答えが出ません**。「油を売る」は本当に油を売っているわけではないし、「耳が痛い」は耳が痛むわけでもありません。ひとまとまりで意味を覚えます。

    ### 体の部分を使う慣用句
    数が多く、テストにもよく出ます。

    - **首**を長くして待つ … 今か今かと待ちこがれる
    - **耳**が痛い … 弱点を言われて聞くのがつらい
    - **手**を焼く … あつかいに困る
    - **顔**が広い … 知り合いが多い

    ### 意味を取りちがえやすいことば
    ここがいちばんの山場です。**反対の意味で覚えてしまっている**ことばがあります。

    | ことば | 正しい意味 | よくあるまちがい |
    |--------|-----------|-----------------|
    | 情けは人のためならず | 親切は自分に返ってくる | 親切はその人のためにならない |
    | 気が置けない | 遠慮がいらない | 油断できない |
    | 役不足 | 力に対して役目が軽すぎる | 力が足りない |

    ### 似た意味どうしをまとめる
    別のことばでも意味が重なるものがあります。組みで覚えると強くなります。

    - 五十歩百歩 ＝ どんぐりの背くらべ（たいしたちがいがない）
    - 一石二鳥 ＝ 一挙両得（一つのことで二つの得）
    - ぬかにくぎ ＝ のれんに腕おし（手ごたえがない）

    ### 四字熟語の見分け方
    組み立てが分かると、意味も推せます。

    - **以心伝心** … 心をもって心に伝える → ことばにしなくても通じる
    - **一朝一夕** … 一つの朝と一つの夕 → ごく短い時間
    - **一長一短** … 長所も短所もある

    ### よくあるまちがい
    - ことわざを字づらだけで判断する … 「情けは人のためならず」がその代表です
    - 似た形のことばを混ぜる … 「一朝一夕」と「一長一短」は形が似ていて意味は別
  MD
  "説明文の読み取り" => <<~'MD',
    ## 説明文の読み取り

    説明文は、**筆者が言いたいことが必ずどこかに書いてあります**。感想で答えるのではなく、文章の中から根きょをさがすのがこつです。

    ### つなぎことばで向きが分かる
    つなぎことば（接続語）は、次に何が来るかの道しるべです。

    | つなぎことば | 次に来るもの |
    |--------------|-------------|
    | だから・そのため | 前の内容の**結果** |
    | しかし・ところが | 前と**反対**の内容 |
    | たとえば | 前の内容の**具体例** |
    | つまり・要するに | 前の内容の**言いかえ・まとめ** |
    | また・そのうえ | **付け加え** |

    **「しかし」のあとには筆者の主張が来やすい**、と覚えておくと要旨をつかみやすくなります。

    ### 指示語は入れかえて確かめる
    「それ」「この方法」などが出てきたら、指すものを前からさがして、**その場に入れて読み直します**。意味が通れば正解です。

    > 氷は新聞紙で包んでからクーラーボックスに入れるとよい。**この方法**なら長くもつ。
    > → 「新聞紙で包んでからクーラーボックスに入れる方法なら長くもつ」　意味が通る

    ### 説明文のよくある型
    多くの説明文は、次の形をしています。

    1. **話題** … 何について書くかを示す
    2. **具体例** … たとえを二つ三つ並べる
    3. **まとめ** … 例に共通することを述べる

    「どちらも」「このように」で始まる段落は、まとめのことが多いです。

    ### 理由を聞かれたら
    「なぜですか」と問われたら、**結論の直前**をさがします。「〜から」「〜ため」で終わる文が答えになっていることがほとんどです。

    ### よくあるまちがい
    - 本文に書いていない、自分の知識で答えてしまう
    - 「ただし」「とはいえ」のあとを読み落として、条件つきの主張を言い切りにしてしまう
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

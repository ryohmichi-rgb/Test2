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

puts "Seed完了: #{Grade.count}学年, #{Unit.count}単元, #{Problem.count}問題"

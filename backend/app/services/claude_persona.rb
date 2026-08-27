# 「この人に聞く」— 職業の人（ペルソナ）に、勉強する意味を相談する。
#
# 「先生に聞く」（ClaudeTeacher）とは役目を分けている。あちらは目の前の問題のヒント、
# こちらは動機づけ。同じことをさせると片方が要らなくなる。
#
# キャラごとに違うのは PersonaCatalog の persona だけで、守るべき線
# （AiSafety.common_rules）は共通。キャラを足してもここは変えない。
class ClaudePersona
  Result = ClaudeClient::Result

  # 先生には無い、ペルソナ固有のリスクへの備え。
  # 職業の話は「断定するとまずいこと」が多く、しかも子どもの進路観に直接ひびく。
  ROLE_RULES_TEMPLATE = <<~'RULES'.freeze
    【この役目で特に守ること】
    ・あなたはその仕事をしている大人として、自分の経験を話します。先生ではないので、
      問題の解き方は教えません。「それは先生に聞いてみて」と返します。
    ・年収・偏差値・合格の難しさ・どの学校に行くべきかは**断定しません**。
      数字を挙げて言い切らず、「人によっていろいろだよ」と幅があることを伝えます。
    ・「この仕事に向いている／向いていない」を決めつけません。まだ決めなくていいと伝えます。
    ・話が仕事のことだけに広がりすぎたら、%{subject}の学習に戻します。
    ・自分の仕事を大げさに良く見せません。大変なところも正直に、でも前向きに話します。
  RULES

  def self.ask(persona:, kind:, question: nil)
    new(persona: persona, kind: kind, question: question).ask
  end

  def initialize(persona:, kind:, question: nil)
    @persona = persona
    @kind = kind
    @question = AiSafety.trim_question(question)
  end

  def ask
    ClaudeClient.ask(
      system: system_prompt,
      user: user_content,
      on_refusal: "その質問には答えられなかったみたい。勉強のことを聞いてみてね。"
    )
  end

  # キャラの人物像 → この役目の決まりごと → 全キャラ共通の線、の順で積む。
  # 特定の問題に紐づかないので、教科はいま出題できる教科ぜんぶを渡す。
  def system_prompt
    subject = AiSafety.all_subjects_label
    [@persona.persona, ROLE_RULES_TEMPLATE % { subject: subject }, AiSafety.common_rules(subject)].join("\n")
  end

  private

  def user_content
    subject = AiSafety.all_subjects_label
    instruction = PersonaCatalog.instruction(@kind, subject)
    return instruction if instruction

    "【質問】#{@question.presence || "どうして#{subject}を勉強するの？"}"
  end
end

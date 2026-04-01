# 词法分析实验说明（Lex）

## 1. 实验目标

本实验要求你基于给定模板实现一个简化版词法分析器（Lexer），将输入源代码切分为 Token 序列，并输出每个 Token 的：

- 行号与列号（1-based）
- Token 类型（kind）
- Token 文本（value）

输出格式要求如下：

```text
[line:col] <kind, value>
```

---

## 2. 环境配置

### 2.1 基础环境

- Linux（建议 Ubuntu）
- Python 3.10+
- clang

### 2.2 安装依赖

在仓库根目录执行：

```bash
pip install -r requirements.txt
```

### 2.3 验证编译器环境（可选）

```bash
scripts/yian_compiler.py labs/lab1/test_cases/hello.an
./tests/yian_workspace/bin/out
```

若输出 `Hello, World!`，说明基础工具链可用。

---

## 3. 代码介绍

### 3.1 目录与文件

- 实验代码：`labs/lab1/lex/lexer.an`
- 测试输入：`labs/lab1/test_cases/01.an ~ 06.an`
- 期望输出：`labs/lab1/test_results/01.txt ~ 06.txt`

### 3.2 主流程

核心流程如下：

1. `lexer_main.an::main()` 读取测试输入文件。
2. `lexer.an::tokenize(...)` 使用有限自动机扫描字符流。
4. 最终写入输出文件（`labs/lab1/output/xx.txt`）。

### 3.3 涉及的类型
- `enum`：[Enum](../../../docs/grammar/02.type_system.md#enum)
- `str`：[str: 字符串切片](../../../docs/grammar/08.standard_library.md#str-字符串切片)
- `String`：[string: 可变字符串](../../../docs/grammar/08.standard_library.md#string-可变字符串)
- `HashSet`：[hash_set: 哈希集合](../../../docs/grammar/08.standard_library.md#hash_set-哈希集合)
- `u8[]`：[切片类型](../../../docs/grammar/02.type_system.md#切片类型)

### 3.4 关键函数

- `emit_word(...)`：将单词分类为 `Keyword` 或 `Ident`。
- `tokenize(...)`：状态机主循环，处理标识符、数字、字符串、字符、操作符、分隔符、注释与空白。
- `push_token(...)`：统一的 Token 输出格式。

### 3.5 需要补全的 TODO

你需要在模板中补全以下逻辑：

1. 单词类别判断：在 `emit_word(...)` 中根据关键字表输出 `Keyword` 或 `Ident`。
2. 部分状态结束时的收束：在部分状态中正确处理 Token 的结束。
3. 行列号更新：在主循环末尾按字符推进 `line/col`，正确处理换行。

### 3.6 测试

你可以通过下面的方式测试你的词法分析器：

1. 修改 `labs/lab1/lex/lexer_main.an` 中所包含的测试名(你也可以构造自己的测试)
2. 命令行执行: `scripts/yian_compiler.py labs/lab1/lex/lexer`
3. 执行生成的可执行文件, 将会在 `labs/lab1/output/` 目录下生成对应的输出文件, 与 `labs/lab1/test_results/` 中的参考输出进行对比。
4. 因为一些神秘小 BUG, 你需要自己创建 `labs/lab1/output/` 目录, 否则输出文件无法生成。

---

## 4. 实验要求

### 4.1 功能要求

至少满足以下能力：

- 正确识别标识符与关键字。
- 正确识别数字、字符串、字符字面量。
- 正确识别常见运算符和分隔符（如 `+`, `+=`, `(`, `)`, `{`, `}` 等）。
- 跳过空白符与行注释（`// ...`）。
- 输出正确的行列号。
- 文件结束时输出 `EOF` Token。

### 4.2 输出要求

- 输出头部保留：`=== Lexer Output ===`
- 每个 Token 一行，格式严格一致。
- 输出顺序必须与扫描顺序一致。

### 4.3 提交要求

提交内容：

- 你的 `labs/lab1/lex/lexer.an`
- 实验报告

---

## 5. 测试与评测规则

你将拿到 `01-06` 号测试及其答案，评分时 `07-10` 号测试作为隐藏评测使用。

### 5.1 公开测试

- 输入：`labs/lab1/test_cases/01.an` ~ `labs/lab1/test_cases/06.an`
- 参考答案：`labs/lab1/test_results/01.txt` ~ `labs/lab1/test_results/06.txt`

### 5.2 隐藏测试（用于评分）

- 输入：`labs/lab1/test_cases/07.an` ~ `labs/lab1/test_cases/10.an` (未包含在公开资料中)
- 参考答案不公开。

---

## 6. 评分标准（100 分）

- 公开测试 01-06：每题 10 分，共 60 分
- 隐藏测试 07-10：每题 10 分，共 40 分
- 评分依据：输出与标准答案逐行一致（允许末尾空行差异由评测脚本统一处理）

---

## 8. 学术诚信

- 禁止抄袭。
- 可以使用 AI 辅助工具，但你最好知道自己的代码在做什么。

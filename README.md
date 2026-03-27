# YIAN 语言编译器

## 运行环境

- Linux(like ubuntu) 
- python3.10+
- clang

## 安装python相关依赖库
```bash
$ pip install -r ./requirements.txt
```

## 编译yian代码

编译并运行一个示例程序 `hello.an`:

```bash
$ scripts/yian_compiler.py lab/test_cases/hello.an
```

可执行文件生成在 `tests/yian_workspace/bin/out`, 执行:

```bash
$ ./tests/yian_workspace/bin/out
```

将会看到终端输出:

```text
Hello, World!
```

说明编译器工作正常

## 重要信息

- 高亮插件目录: `ide-support`, 包含了适用于VSCode的语法高亮插件, 右键安装
- 语法文档: `docs/grammar`, 用于快速上手yian语言的语法规则
- lab目录: `lab`

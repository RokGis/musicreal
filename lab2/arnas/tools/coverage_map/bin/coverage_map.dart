// LD2 8.2.a (Arnas): sakinių ir sprendimų sąrašas iš Dart sintaksės medžio.
//
// Analizuojamas tik išeities tekstas (analyzer parseString), kodas
// nevykdomas ir nekeičiamas. Rezultatas – JSON, kurį function_coverage.py
// susieja su LCOV DA įrašais.
//
// Taisyklės:
//  * sakinys – kiekvienas AST Statement mazgas, išskyrus Block, ir kiekvienas
//    išraiškos kūnas `=>` (lygiavertis vienam return sakiniui);
//  * sprendimas – IfStatement (taip pat išvardijami ?:, &&, ||, ciklai,
//    switch, catch ir collection if, jei jų yra);
//  * if true baigtį liudija pirmas then šakos sakinys; false baigtį – pirmas
//    else šakos sakinys arba, kai else nėra, kitas sakinys po if, bet tik tada,
//    kai then šaka visada baigiasi return arba throw.
//
// Naudojimas (iš repozitorijos šaknies):
//   dart run lab2/arnas/tools/coverage_map/bin/coverage_map.dart \
//       lib/pages/home/home_widget.dart friendsFeedQuery FriendFeed.build

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln('Naudojimas: coverage_map.dart <failas.dart> <funkcija|Klasė.metodas>...');
    exit(64);
  }
  final path = args.first;
  final content = File(path).readAsStringSync();
  final parsed = parseString(content: content, path: path, throwIfDiagnostics: true);
  final finder = _TargetFinder(content, args.skip(1).toSet());
  parsed.unit.accept(finder);

  final result = <String, Object>{'file': path};
  for (final name in args.skip(1)) {
    final target = finder.found[name];
    if (target == null) {
      stderr.writeln('Nerasta: $name');
      exit(1);
    }
    result[name] = _describe(target, parsed.lineInfo, content);
  }
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(result));
}

class _TargetFinder extends RecursiveAstVisitor<void> {
  _TargetFinder(this.content, this.names);

  final String content;
  final Set<String> names;
  final found = <String, AstNode>{};

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is CompilationUnit && names.contains(node.name.lexeme)) {
      found[node.name.lexeme] = node;
    }
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final owner = node.thisOrAncestorOfType<ClassDeclaration>();
    if (owner != null) {
      // Klasės pavadinimas imamas iš teksto, kad nepriklausytų nuo analyzer API versijos.
      final header = content.substring(owner.offset, owner.offset + 200);
      final match = RegExp(r'class\s+(\w+)').firstMatch(header);
      final qualified = '${match?.group(1)}.${node.name.lexeme}';
      if (names.contains(qualified)) found[qualified] = node;
    }
    super.visitMethodDeclaration(node);
  }
}

Map<String, Object?> _describe(AstNode target, LineInfo lines, String content) {
  final collector = _Collector();
  target.accept(collector);

  int line(int offset) => lines.getLocation(offset).lineNumber;
  String text(AstNode node) {
    final shown = node is ExpressionFunctionBody ? node.expression : node;
    final first = content.substring(shown.offset, shown.end).split('\n').first.trim();
    return first.length > 80 ? '${first.substring(0, 77)}...' : first;
  }

  final ids = <AstNode, String>{};
  final statements = <Map<String, Object?>>[];
  for (final node in collector.statements) {
    final id = 'S${statements.length + 1}';
    ids[node] = id;
    statements.add({
      'id': id,
      'kind': node is ExpressionFunctionBody ? 'ExpressionFunctionBody (=>)' : node.runtimeType.toString().replaceAll('Impl', ''),
      'start_line': line(node.offset),
      'end_line': line(node.end),
      'text': text(node),
    });
  }

  final decisions = <Map<String, Object?>>[];
  for (final node in collector.ifs) {
    final trueWitness = _firstStatement(node.thenStatement);
    Statement? falseWitness;
    String rule;
    if (node.elseStatement != null) {
      falseWitness = _firstStatement(node.elseStatement!);
      rule = 'pirmas else šakos sakinys';
    } else if (_alwaysExits(node.thenStatement) && node.parent is Block) {
      final siblings = (node.parent as Block).statements;
      final index = siblings.indexOf(node);
      falseWitness = index + 1 < siblings.length ? siblings[index + 1] : null;
      rule = 'kitas sakinys po if (then šaka baigiasi return/throw)';
    } else {
      rule = 'nenustatoma iš LCOV (then šaka ne visada baigiasi)';
    }
    decisions.add({
      'id': 'D${decisions.length + 1}',
      'kind': 'IfStatement',
      'line': line(node.offset),
      'condition': node.expression.toSource(),
      'true_witness': ids[trueWitness],
      'false_witness': falseWitness == null ? null : ids[falseWitness],
      'false_rule': rule,
    });
  }

  return {
    'start_line': line(target.offset),
    'end_line': line(target.end),
    'statements': statements,
    'decisions': decisions,
    'other_decision_constructs': collector.otherDecisions
        .map((n) => {'line': line(n.offset), 'kind': n.runtimeType.toString().replaceAll('Impl', ''), 'text': text(n)})
        .toList(),
    'null_aware_operators': collector.nullAware
        .map((t) => {'line': line(t.offset), 'operator': t.lexeme})
        .toList(),
  };
}

Statement _firstStatement(Statement branch) =>
    branch is Block && branch.statements.isNotEmpty ? branch.statements.first : branch;

bool _alwaysExits(Statement branch) {
  final last = branch is Block ? (branch.statements.isEmpty ? null : branch.statements.last) : branch;
  return last is ReturnStatement ||
      (last is ExpressionStatement && last.expression is ThrowExpression);
}

class _Collector extends GeneralizingAstVisitor<void> {
  final statements = <AstNode>[];
  final ifs = <IfStatement>[];
  final otherDecisions = <AstNode>[];
  final nullAware = <Token>[];

  @override
  void visitStatement(Statement node) {
    if (node is! Block) statements.add(node);
    if (node is IfStatement) ifs.add(node);
    if (node is ForStatement || node is WhileStatement || node is DoStatement || node is SwitchStatement) {
      otherDecisions.add(node);
    }
    super.visitStatement(node);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    statements.add(node);
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    otherDecisions.add(node);
    super.visitConditionalExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final op = node.operator.type;
    if (op == TokenType.AMPERSAND_AMPERSAND || op == TokenType.BAR_BAR) otherDecisions.add(node);
    if (op == TokenType.QUESTION_QUESTION) nullAware.add(node.operator);
    super.visitBinaryExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.operator.type == TokenType.QUESTION_PERIOD) nullAware.add(node.operator);
    super.visitPropertyAccess(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.operator?.type == TokenType.QUESTION_PERIOD) nullAware.add(node.operator!);
    super.visitMethodInvocation(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    otherDecisions.add(node);
    super.visitCatchClause(node);
  }

  @override
  void visitIfElement(IfElement node) {
    otherDecisions.add(node);
    super.visitIfElement(node);
  }
}

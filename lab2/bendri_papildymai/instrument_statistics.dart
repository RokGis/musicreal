import 'dart:convert';
import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class Collector extends RecursiveAstVisitor<void> {
  Collector(this.lineInfo);
  final dynamic lineInfo;
  String? method;
  final edits = <(int,String,int)>[];
  final entries = <Map<String,dynamic>>[];
  String id(AstNode node,String kind) {
    final pos=lineInfo.getLocation(node.offset);
    final key='$method:$kind:${pos.lineNumber}:${pos.columnNumber}';
    entries.add({'id':key,'method':method,'kind':kind,'line':pos.lineNumber,
      'column':pos.columnNumber,'source':node.toSource()});
    return key;
  }
  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!['_emotionTotals','_topSongs'].contains(node.name.lexeme)) return;
    method=node.name.lexeme;
    node.body.accept(this);
    method=null;
  }
  @override
  void visitBlock(Block node) {
    if (method==null) return;
    for (final statement in node.statements) {
      if (statement is! Block) {
        final key=id(statement,'statement');
        edits.add((statement.offset,"StatisticsProbe.statement('$key'); ",0));
      }
    }
    super.visitBlock(node);
  }
  void bareStatement(Statement statement) {
    if (statement is Block) return;
    final key=id(statement,'statement');
    edits.add((statement.offset,"{ StatisticsProbe.statement('$key'); ",0));
    edits.add((statement.end,' }',4));
  }
  @override
  void visitIfStatement(IfStatement node) {
    final key=id(node.expression,'decision');
    edits.add((node.expression.offset,"StatisticsProbe.condition('$key', (",1));
    edits.add((node.expression.end,'))',2));
    bareStatement(node.thenStatement);
    if (node.elseStatement!=null) bareStatement(node.elseStatement!);
    super.visitIfStatement(node);
  }
  @override
  void visitForStatement(ForStatement node) {
    final parts=node.forLoopParts;
    if (parts is ForEachParts) {
      final key=id(parts.iterable,'loop-decision');
      edits.add((parts.iterable.offset,"StatisticsProbe.iterations('$key', (",1));
      edits.add((parts.iterable.end,'))',2));
    }
    super.visitForStatement(node);
  }
}

void main(List<String> args) {
  final source=File(args[0]).readAsStringSync();
  final parsed=parseString(content:source,path:args[0]);
  final visitor=Collector(parsed.lineInfo);
  parsed.unit.accept(visitor);
  var result=source;
  visitor.edits.sort((a,b)=>a.$1==b.$1?b.$3.compareTo(a.$3):b.$1.compareTo(a.$1));
  for (final edit in visitor.edits) {
    result=result.replaceRange(edit.$1,edit.$1,edit.$2);
  }
  result="import '${File(args[3]).absolute.uri}';\n$result";
  File(args[1]).writeAsStringSync(result);
  File(args[2]).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(visitor.entries));
  print('${visitor.entries.length} mapped nodes');
}

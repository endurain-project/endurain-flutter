import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as p;

/// Fails when a public declaration in `lib/` is referenced nowhere in `lib/`
/// outside its own declaration.
///
/// Usage: `dart run tool/check_dead_code.dart [--allowlist <file>] [--root <dir>]`
///
/// Allowlist lines are `<path relative to root>:<Name>` for top-level
/// declarations and `<path>:<Class>.<member>` for members. `#` starts a
/// comment.
Future<void> main(List<String> arguments) async {
  var root = Directory.current.path;
  var allowlistPath = '.github/dead-code-allowlist.txt';
  for (var i = 0; i < arguments.length; i++) {
    if (arguments[i] == '--root' && i + 1 < arguments.length) {
      root = p.absolute(arguments[++i]);
    } else if (arguments[i] == '--allowlist' && i + 1 < arguments.length) {
      allowlistPath = arguments[++i];
    }
  }

  final allowlistFile = File(p.join(root, allowlistPath));
  final allowlist = allowlistFile.existsSync()
      ? parseAllowlist(allowlistFile.readAsLinesSync())
      : <String>{};

  final findings = await findUnreferenced(root);
  final reported = findings.where((f) => !allowlist.contains(f.key)).toList();
  final unusedAllow = allowlist.difference({for (final f in findings) f.key});

  for (final f in reported) {
    stdout.writeln('${f.key}  (${f.kind}, line ${f.line})');
  }
  for (final key in unusedAllow) {
    stdout.writeln('stale allowlist entry: $key');
  }
  if (reported.isNotEmpty || unusedAllow.isNotEmpty) {
    stderr.writeln(
      '${reported.length} unreferenced public declaration(s), '
      '${unusedAllow.length} stale allowlist entr(ies). Delete the code or '
      'add a justified entry to $allowlistPath.',
    );
    exitCode = 1;
  } else {
    stdout.writeln('No unreferenced public declarations in lib/.');
  }
}

/// Parses allowlist lines, ignoring blanks and `#` comments.
Set<String> parseAllowlist(Iterable<String> lines) {
  final result = <String>{};
  for (final raw in lines) {
    final line = raw.split('#').first.trim();
    if (line.isNotEmpty) result.add(line);
  }
  return result;
}

/// Member names the framework or generated/serialization code calls
/// implicitly, never by an explicit reference in `lib/`.
const implicitMemberNames = {
  'toString',
  'hashCode',
  '==',
  'noSuchMethod',
  'build',
  'createState',
  'dispose',
  'toJson',
  'fromJson',
};

class DeadCodeFinding {
  const DeadCodeFinding(this.file, this.name, this.kind, this.line);

  final String file;
  final String name;
  final String kind;
  final int line;

  String get key => '$file:$name';
}

class _Decl {
  _Decl(this.element, this.finding, this.node);

  final Element element;
  final DeadCodeFinding finding;
  final AstNode node;
}

bool _isGenerated(String relPath) =>
    relPath.startsWith('lib/l10n/app_localizations') ||
    relPath.endsWith('.g.dart') ||
    relPath.endsWith('.freezed.dart');

Element _normalize(Element e) {
  var r = e.baseElement;
  if (r is PropertyAccessorElement) {
    r = r.variable.baseElement;
  }
  return r;
}

bool _isPublic(String? name) => name != null && !name.startsWith('_');

bool _hasAnnotation(AnnotatedNode node, String name) =>
    node.metadata.any((m) => m.name.name == name);

bool _hasOverride(AnnotatedNode node) => _hasAnnotation(node, 'override');

/// Resolves `<root>/lib` and returns public declarations that nothing in
/// `lib/` references outside the declaration itself.
Future<List<DeadCodeFinding>> findUnreferenced(
  String root, {
  String? sdkPath,
}) async {
  final libDir = p.join(root, 'lib');
  final collection = AnalysisContextCollection(
    includedPaths: [libDir],
    sdkPath: sdkPath,
  );
  final decls = <_Decl>[];
  // element -> list of (file, offset) reference sites.
  final refs = <Element, List<(String, int)>>{};

  for (final context in collection.contexts) {
    final files =
        context.contextRoot
            .analyzedFiles()
            .where((f) => f.endsWith('.dart') && p.isWithin(libDir, f))
            .toList()
          ..sort();
    for (final path in files) {
      final result = await context.currentSession.getResolvedUnit(path);
      if (result is! ResolvedUnitResult) continue;
      final rel = p.relative(path, from: root).replaceAll(r'\', '/');
      if (!_isGenerated(rel)) {
        result.unit.accept(_DeclCollector(rel, result, decls));
      }
      result.unit.accept(_RefCollector(path, refs));
    }
  }

  final findings = <DeadCodeFinding>[];
  for (final d in decls) {
    final declPath = p.join(root, d.finding.file);
    final sites = refs[d.element] ?? const [];
    final used = sites.any(
      (s) => s.$1 != declPath || s.$2 < d.node.offset || s.$2 >= d.node.end,
    );
    if (!used) findings.add(d.finding);
  }
  findings.sort((a, b) => a.key.compareTo(b.key));
  return findings;
}

class _DeclCollector extends RecursiveAstVisitor<void> {
  _DeclCollector(this.file, this.result, this.out);

  final String file;
  final ResolvedUnitResult result;
  final List<_Decl> out;

  void _add(
    Element? element,
    String name,
    String kind,
    AstNode node,
    Token nameToken,
  ) {
    if (element == null) return;
    // Explicitly test-only by design.
    if (node is AnnotatedNode && _hasAnnotation(node, 'visibleForTesting')) {
      return;
    }
    out.add(
      _Decl(
        _normalize(element),
        DeadCodeFinding(
          file,
          name,
          kind,
          result.lineInfo.getLocation(nameToken.offset).lineNumber,
        ),
        node,
      ),
    );
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is CompilationUnit &&
        _isPublic(node.name.lexeme) &&
        node.name.lexeme != 'main') {
      _add(
        node.declaredFragment?.element,
        node.name.lexeme,
        'function',
        node,
        node.name,
      );
    }
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    for (final v in node.variables.variables) {
      if (_isPublic(v.name.lexeme)) {
        _add(
          v.declaredFragment?.element,
          v.name.lexeme,
          'variable',
          node,
          v.name,
        );
      }
    }
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) => _alias(node);

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) => _alias(node);

  void _alias(TypeAlias node) {
    if (_isPublic(node.name.lexeme)) {
      _add(
        node.declaredFragment?.element,
        node.name.lexeme,
        'typedef',
        node,
        node.name,
      );
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _type(
      node,
      node.namePart.typeName,
      'class',
      node.declaredFragment?.element,
      node.body,
    );
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _type(node, node.name, 'mixin', node.declaredFragment?.element, node.body);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _type(
      node,
      node.namePart.typeName,
      'enum',
      node.declaredFragment?.element,
      node.body,
    );
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _type(
      node,
      node.namePart.typeName,
      'extension type',
      node.declaredFragment?.element,
      node.body,
    );
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    final name = node.name;
    if (name != null && _isPublic(name.lexeme)) {
      _add(
        node.declaredFragment?.element,
        name.lexeme,
        'extension',
        node,
        name,
      );
    }
    final owner = name?.lexeme ?? '<unnamed extension>';
    if (name == null || _isPublic(name.lexeme)) {
      _members(owner, node.body.members, isEnum: false);
    }
  }

  void _type(
    CompilationUnitMember node,
    Token name,
    String kind,
    Element? element,
    AstNode body,
  ) {
    if (!_isPublic(name.lexeme)) return;
    _add(element, name.lexeme, kind, node, name);
    if (body is BlockClassBody) {
      _members(name.lexeme, body.members, isEnum: false);
    } else if (body is EnumBody) {
      _members(name.lexeme, body.members, isEnum: true, enumBody: body);
    }
  }

  void _members(
    String owner,
    List<ClassMember> members, {
    required bool isEnum,
    EnumBody? enumBody,
  }) {
    if (enumBody != null) {
      for (final c in enumBody.constants) {
        if (_isPublic(c.name.lexeme)) {
          _add(
            c.declaredFragment?.element,
            '$owner.${c.name.lexeme}',
            'enum value',
            c,
            c.name,
          );
        }
      }
    }
    for (final m in members) {
      if (m is MethodDeclaration) {
        final name = m.name.lexeme;
        if (!_isPublic(name) || _hasOverride(m) || m.isOperator) continue;
        if (implicitMemberNames.contains(name)) continue;
        _add(m.declaredFragment?.element, '$owner.$name', 'method', m, m.name);
      } else if (m is FieldDeclaration) {
        for (final v in m.fields.variables) {
          final name = v.name.lexeme;
          if (!_isPublic(name) || _hasOverride(m)) continue;
          _add(v.declaredFragment?.element, '$owner.$name', 'field', m, v.name);
        }
      } else if (m is ConstructorDeclaration) {
        final name = m.name;
        // Unnamed constructors are covered by the class itself.
        if (name == null || !_isPublic(name.lexeme)) continue;
        if (implicitMemberNames.contains(name.lexeme)) continue;
        _add(
          m.declaredFragment?.element,
          '$owner.${name.lexeme}',
          'constructor',
          m,
          name,
        );
      }
    }
  }
}

class _RefCollector extends RecursiveAstVisitor<void> {
  _RefCollector(this.file, this.refs);

  final String file;
  final Map<Element, List<(String, int)>> refs;

  void _record(Element? e, int offset) {
    if (e == null) return;
    final element = _normalize(e);
    refs.putIfAbsent(element, () => []).add((file, offset));
    // Using an implementation also uses the interface member it implements
    // (callers often hold the concrete type).
    final owner = element.enclosingElement;
    if (owner is InterfaceElement && element.name != null) {
      final name = element.name!;
      for (final supertype in owner.allSupertypes) {
        final st = supertype.element;
        for (final overridden in [
          st.getMethod(name),
          st.getGetter(name),
          st.getSetter(name),
          st.getField(name),
        ]) {
          if (overridden != null) {
            refs.putIfAbsent(_normalize(overridden), () => []).add((
              file,
              offset,
            ));
          }
        }
      }
    }
    // Extensions are applied implicitly, so using a member uses the extension.
    if (owner is ExtensionElement) {
      refs.putIfAbsent(_normalize(owner), () => []).add((file, offset));
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!node.inDeclarationContext()) {
      _record(node.element, node.offset);
    }
    super.visitSimpleIdentifier(node);
  }

  // Assignments and increments resolve to read/write elements rather than
  // to the identifier's own element.
  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _record(node.readElement, node.offset);
    _record(node.writeElement, node.offset);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _record(node.readElement, node.offset);
    _record(node.writeElement, node.offset);
    super.visitPrefixExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _record(node.readElement, node.offset);
    _record(node.writeElement, node.offset);
    super.visitPostfixExpression(node);
  }

  @override
  void visitNamedType(NamedType node) {
    _record(node.element, node.offset);
    super.visitNamedType(node);
  }

  @override
  void visitPatternField(PatternField node) {
    _record(node.element, node.offset);
    super.visitPatternField(node);
  }

  @override
  void visitAnnotation(Annotation node) {
    _record(node.element, node.offset);
    super.visitAnnotation(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _record(node.element, node.offset);
    super.visitConstructorName(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _record(node.element, node.offset);
    super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    _record(node.element, node.offset);
    super.visitRedirectingConstructorInvocation(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _record(node.constructorElement, node.offset);
    super.visitEnumConstantDeclaration(node);
  }
}

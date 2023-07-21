# pip install git+https://github.com/nigelsmall/py2neo.git@py2neo-3.1.2
import py2neo
graph = py2neo.Graph("neo4j://localhost:7474")
def run(cypher):
    print(cypher)
    try:
        graph.run(cypher)
        return True
    except:
        print("failed.")
types = ["Directory","File","Function","FunctionDef","ParameterList","Parameter","Identifier","ParameterType","ReturnType","CompoundStatement","ReturnStatement","PrimaryExpression","WhileStatement","ExpressionStatement","UnaryExpression","IncDec","TryStatement","CatchList","CatchStatement","ShiftExpression","CallExpression","ArgumentList","Callee","MemberAccess","PostIncDecOperationExpression","Argument","UnaryOperationExpression","UnaryOperator","Condition","EqualityExpression","IdentifierDeclStatement","IdentifierDecl","AssignmentExpression","IdentifierDeclType","ArrayIndexing","IfStatement","RelationalExpression","CFGEntryNode","CFGExitNode","CFGErrorNode","Symbol","DeclStmt","Decl","Expression","SwitchStatement","BreakStatement","Label","AdditiveExpression","MultiplicativeExpression","CastExpression","CastTarget","ElseStatement","ContinueStatement","AndExpression","ClassDefStatement","SizeofExpression","SizeofOperand","Sizeof","Statement","ClassDef","OrExpression","ForStatement","ConditionalExpression","ForInit","PtrMemberAccess","InclusiveOrExpression","ThrowStatement","CFGExceptionNode","BitAndExpression","GotoStatement","InitializerList","InfiniteForNode","DoStatement","ExclusiveOrExpression"]
for type in types:
    if run('MATCH (n {type:"%s"}) SET n :%s' % (type, type)):
        run('MATCH (n {type:"%s"}) REMOVE n.type' % (type,))


#include <llvm-15/llvm/IR/Constants.h>
#include <llvm-15/llvm/IR/GlobalAlias.h>
#include <llvm/ADT/StringRef.h>
#include <llvm/Analysis/AliasAnalysis.h>
#include <llvm/Analysis/CallGraph.h>
#include <llvm/IR/BasicBlock.h>
#include <llvm/IR/Constants.h>
#include <llvm/IR/DebugInfo.h>
#include <llvm/IR/DebugInfoMetadata.h>
#include <llvm/IR/DebugLoc.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/GlobalIFunc.h>
#include <llvm/IR/InstIterator.h>
#include <llvm/IR/InstrTypes.h>
#include <llvm/IR/Instruction.h>
#include <llvm/IR/Instructions.h>
#include <llvm/IR/IntrinsicInst.h>
#include <llvm/IR/LegacyPassManager.h>
#include <llvm/IR/Metadata.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/Operator.h>
#include <llvm/IR/Type.h>
#include <llvm/IR/Value.h>
#include <llvm/Pass.h>
#include <llvm/Support/raw_ostream.h>
#include <llvm/Transforms/IPO/PassManagerBuilder.h>

#include <set>
#include <string>

using namespace llvm;

namespace {

void inspect_use(const Use &use, const StringRef &referer_name);
void handle_constant_ref(const Constant *cnst, const StringRef &referer_name);

bool bad_var_name(const StringRef &var_name) {
  return var_name.startswith("llvm.") || var_name.startswith(".");
}

std::map<std::pair<std::string, std::string>, int> E;

void emit_reference(const char *type, const StringRef &referee_name,
                    const StringRef &referer_name) {
  if (bad_var_name(referee_name))
    return;

  E[std::make_pair(referer_name.str(), referee_name.str())]++;

  // print a -> b
  // errs() << type << "," << referer_name << "," << referee_name << "\n";
  // the callinst must have DISubprogram
  // DISubprogram *disubprogram = callee->getSubprogram();
  // if (disubprogram) {
  //   errs() << disubprogram->getName() << "\n";
  // }
}

void export_graph() {
  for (const auto &kv : E) {
    errs() << kv.first.first << "," << kv.first.second << "," << kv.second
           << "\n";
  }
}

// https://llvm.org/doxygen/classllvm_1_1Constant.html
void handle_constant_ref(const Constant *cnst, const StringRef &referer_name) {
  if (const auto *cnst_data = dyn_cast<ConstantData>(cnst)) {
    // pass

  } else if (const auto *cnst_expr = dyn_cast<ConstantExpr>(cnst)) {
    for (const auto &use2 : cnst_expr->operands())
      inspect_use(use2, referer_name);

  } else if (const auto *cnst_aggr = dyn_cast<ConstantAggregate>(cnst)) {
    // errs() << ">> constant is aggregate: " << *cnst_aggr << "\n";
    for (const auto &use2 : cnst_aggr->operands())
      inspect_use(use2, referer_name);

  } else if (const auto *baddr = dyn_cast<BlockAddress>(cnst)) {
    emit_reference("use", baddr->getName(), referer_name);

  } else if (const auto *alias = dyn_cast<GlobalAlias>(cnst)) {
    emit_reference("use", alias->getName(), referer_name);
  } else if (const auto *func = dyn_cast<Function>(cnst)) {
    emit_reference("use", func->getName(), referer_name);
  } else if (const auto *ifunc = dyn_cast<GlobalIFunc>(cnst)) {
    emit_reference("use", ifunc->getName(), referer_name);
  } else if (const auto *gvar2 = dyn_cast<GlobalVariable>(cnst)) {
    emit_reference("use", gvar2->getName(), referer_name);

  } else {
    errs() << ">> unknown constant type: " << *cnst
           << " name:" << cnst->getName() << "\n";
  }
}

// https://llvm.org/doxygen/classllvm_1_1Use.html
void inspect_use(const Use &use, const StringRef &referer_name) {
  if (const auto *cnst = dyn_cast<Constant>(use)) {
    handle_constant_ref(cnst, referer_name);
  } else if (const auto *bb = dyn_cast<BasicBlock>(use)) {
  } else if (const auto *inst = dyn_cast<Instruction>(use)) {
  } else if (const auto *val = dyn_cast<Value>(use)) {
  } else {
    errs() << ">> unknown use type: " << *use << " name:" << use->getName()
           << "\n";
  }
}

void process_global_var(const GlobalVariable &gvar) {
  const auto &gvar_name = gvar.getName();
  if (bad_var_name(gvar_name))
    return;

  if (!gvar.hasInitializer())
    return;

  const auto *gvar_value = gvar.getInitializer();
  // if (gvar_value->isNullValue())
  //   return;

  // global variable's type is always pointer
  // const auto *gvar_type = gvar.getType()->getPointerElementType();

  // if (gvar_type->isIntOrIntVectorTy() || gvar_type->isFloatingPointTy()) {
  //   // pass
  // } else if (gvar_type->isArrayTy() || gvar_type->isStructTy()) {
  //   // errs() << ">> global array or struct: " << gvar_name << "\n";
  //   for (const auto &use : gvar_value->operands())
  //     inspect_use(use, gvar_name);
  // } else if (gvar_type->isPointerTy()) {
  //   // errs() << ">> global pointer variable: " << gvar_name << "\n";
  //   for (const auto &use : gvar_value->operands())
  //     inspect_use(use, gvar_name);
  // } else {
  //   errs() << ">> unknown global variable type: " << *gvar_type << "\n";
  // }
  for (const auto &use : gvar_value->operands())
    inspect_use(use, gvar_name);
}

class MyCallGraphPass : public ModulePass {
public:
  static char ID;

  MyCallGraphPass() : ModulePass(ID) {}

  virtual bool runOnModule(Module &M) override {
    const auto &gvars = M.getGlobalList();
    for (const auto &gvar : gvars)
      process_global_var(gvar);

    const auto &funcs = M.getFunctionList();
    for (const auto &func : funcs) {
      StringRef func_name = func.getName();
      for (const auto &bb : func) {
        for (const auto &inst : bb) {
          // process call instruction
          //           if (const CallInst *call_inst =
          //           dyn_cast<CallInst>(&inst)) {
          //             if (Function *callee = call_inst->getCalledFunction())
          //               emit_reference("call", callee->getName(), func_name);
          //           } else if (const InvokeInst *invk_inst =
          //                          dyn_cast<InvokeInst>(&inst)) {
          //             if (Function *callee = invk_inst->getCalledFunction())
          //               emit_reference("call", callee->getName(), func_name);
          //           }

          // process operands (callee function, global variable, etc.)
          for (const auto &use : inst.operands())
            inspect_use(use, func_name);
        }
      }
    }

    export_graph();
    return false;
  }
};
} // namespace

char MyCallGraphPass::ID = 0;
static RegisterPass<MyCallGraphPass> X("refgraph", "Reference Graph Pass",
                                       false /* Only looks at CFG */,
                                       false /* Analysis Pass */);

static RegisterStandardPasses Y(PassManagerBuilder::EP_EarlyAsPossible,
                                [](const PassManagerBuilder &Builder,
                                   legacy::PassManagerBase &PM) {
                                  PM.add(new MyCallGraphPass());
                                });

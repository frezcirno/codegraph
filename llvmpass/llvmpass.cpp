#include <cassert>
#include <llvm/ADT/StringRef.h>
#include <llvm/Analysis/AliasAnalysis.h>
#include <llvm/Analysis/CallGraph.h>
#include <llvm/IR/BasicBlock.h>
#include <llvm/IR/CFG.h>
#include <llvm/IR/Constants.h>
#include <llvm/IR/DebugInfo.h>
#include <llvm/IR/DebugInfoMetadata.h>
#include <llvm/IR/DebugLoc.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/GlobalAlias.h>
#include <llvm/IR/GlobalIFunc.h>
#include <llvm/IR/InlineAsm.h>
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
#include <llvm/Support/FileSystem.h>
#include <llvm/Support/Path.h>
#include <llvm/Support/raw_ostream.h>
#include <llvm/Transforms/IPO/PassManagerBuilder.h>

#include <set>
#include <string>

#include "json/json.h"

using namespace llvm;

namespace {

void inspect_use(const Value *value, const StringRef &referer_name);
void handle_constant_ref(const Constant *cnst, const StringRef &referer_name);

std::map<std::pair<std::string, std::string>, int> E;

bool bad_var_name(const StringRef &var_name) {
  return var_name.startswith("llvm.") || var_name.startswith(".");
}

// bool exists(const StringRef &referer_name, const StringRef &referee_name) {
//   return E.find(std::make_pair(referer_name.str(), referee_name.str())) !=
//          E.end();
// }

void emit_reference(const StringRef &referee_name,
                    const StringRef &referer_name) {
  if (bad_var_name(referee_name))
    return;

  E[std::make_pair(referer_name.str(), referee_name.str())]++;
}

void export_graph() {
  for (const auto &kv : E) {
    errs() << kv.first.first << "," << kv.first.second << "," << kv.second
           << "\n";
  }
}

// https://llvm.org/doxygen/classllvm_1_1Constant.html
void handle_constant_ref(const Constant *cnst, const StringRef &referer_name) {
  // -> llvm::ConstantData
  if (dyn_cast<ConstantData>(cnst)) {
    // pass
    assert(cnst->getNumOperands() == 0);
  }

  // -> llvm::ConstantExpr
  else if (dyn_cast<ConstantExpr>(cnst)) {
    for (const auto &use : cnst->operands())
      inspect_use(use, referer_name);
  }

  // -> llvm::ConstantAggregate
  else if (dyn_cast<ConstantAggregate>(cnst)) {
    for (const auto &use : cnst->operands())
      inspect_use(use, referer_name);
  }

  // -> llvm::BlockAddress
  else if (const auto *baddr = dyn_cast<BlockAddress>(cnst)) {
    emit_reference(baddr->getName(), referer_name);
  }

  // -> llvm::GlobalValue
  else if (const auto *gvar = dyn_cast<GlobalValue>(cnst)) {
    // -> llvm::GlobalValue -> llvm::GlobalAlias
    // -> llvm::GlobalValue -> llvm::GlobalObject
    // -> llvm::GlobalValue -> llvm::GlobalObject -> llvm::Function
    // -> llvm::GlobalValue -> llvm::GlobalObject -> llvm::GlobalIFunc
    // -> llvm::GlobalValue -> llvm::GlobalObject -> llvm::GlobalVariable
    emit_reference(gvar->getName(), referer_name);
  }

  // -> llvm::NoCFIValue
  // -> llvm::DSOLocalEquivalent
  else {
    errs() << ">> unknown constant type: " << *cnst
           << " name:" << cnst->getName() << "\n";
  }
}

// use another llvm::Value
// only check Constant
// https://llvm.org/doxygen/classllvm_1_1Use.html
// https://llvm.org/doxygen/classllvm_1_1Value.html
void inspect_use(const Value *value, const StringRef &referer_name) {
  // -> llvm::User -> llvm::Constant
  if (const Constant *cnst = dyn_cast<Constant>(value)) {
    handle_constant_ref(cnst, referer_name);
  }

  // -> llvm::User -> llvm::Instruction
  else if (dyn_cast<Instruction>(value)) {
  }
  // -> llvm::User -> llvm::Operator
  else if (dyn_cast<Operator>(value)) {
  }
  // -> llvm::User( -> llvm::DerivedUser)
  else if (dyn_cast<User>(value)) {
  }

  // -> llvm::Argument
  else if (dyn_cast<Argument>(value)) {
  }
  // -> llvm::BasicBlock
  else if (dyn_cast<BasicBlock>(value)) {
  }
  // -> llvm::InlineAsm
  else if (dyn_cast<InlineAsm>(value)) {
  }
  // -> llvm::MetadataAsValue
  else if (dyn_cast<MetadataAsValue>(value)) {
  }
}

class MyCallGraphPass : public ModulePass {
public:
  static char ID;

  MyCallGraphPass() : ModulePass(ID) {}

  virtual bool runOnModule(Module &M) override {
    const auto &gvars = M.getGlobalList();
    for (const auto &gvar : gvars) {
      const auto &gvar_name = gvar.getName();
      if (bad_var_name(gvar_name))
        continue;
      if (gvar.hasInitializer()) {
        const auto *gvar_init = gvar.getInitializer();
        handle_constant_ref(gvar_init, gvar_name);
      }
    }

    const auto &funcs = M.getFunctionList();
    for (const auto &func : funcs) {
      StringRef func_name = func.getName();
      for (const auto &bb : func) {
        for (const auto &inst : bb) {
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

namespace {

using SourceRange = std::pair<DebugLoc, DebugLoc>;

cl::opt<std::string> OutDir("cfg-outdir", cl::desc("Output directory"),
                            cl::value_desc("directory"), cl::init("."));

// Not available in older LLVM versions
static std::string getNameOrAsOperand(const Value *V) {
  if (!V->getName().empty()) {
    return std::string(V->getName());
  }

  std::string BBName;
  raw_string_ostream OS(BBName);
  V->printAsOperand(OS, false);
  return OS.str();
}

// Adapted from seadsa
static const Value *getCalledFunctionThroughAliasesAndCasts(const Value *V) {
  const Value *CalledV = V->stripPointerCasts();

  if (const Function *F = dyn_cast<const Function>(CalledV)) {
    return F;
  }

  if (const GlobalAlias *GA = dyn_cast<const GlobalAlias>(CalledV)) {
    if (const Function *F =
            dyn_cast<const Function>(GA->getAliasee()->stripPointerCasts())) {
      return F;
    }
  }

  return CalledV;
}
// Adapted from llvm::CFGPrinter::getSimpleNodeLabel
static std::string getBBLabel(const BasicBlock *BB) {
  if (!BB->getName().empty()) {
    return BB->getName().str();
  }

  std::string Str;
  raw_string_ostream OS(Str);

  BB->printAsOperand(OS, false);
  return OS.str();
}

static SourceRange getSourceRange(const BasicBlock *BB) {
  DebugLoc Start;
  for (const auto &I : *BB) {
    const auto &DbgLoc = I.getDebugLoc();
    if (DbgLoc) {
      Start = DbgLoc;
      break;
    }
  }

  return {Start, BB->getTerminator()->getDebugLoc()};
}

class MyCFGPass : public ModulePass {
public:
  static char ID;

  MyCFGPass() : ModulePass(ID) {}

  virtual bool runOnModule(Module &M) override;
};

bool MyCFGPass::runOnModule(Module &M) {
  SmallPtrSet<const BasicBlock *, 32> SeenBBs;
  SmallVector<const BasicBlock *, 32> Worklist;

  Json::Value JFuncs, JBlocks, JEdges, JCalls, JUnresolvedCalls, JReturns;

  for (const auto &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    SeenBBs.clear();
    Worklist.clear();
    Worklist.push_back(&F.getEntryBlock());

    JBlocks.clear();
    JEdges.clear();
    JCalls.clear();
    JUnresolvedCalls.clear();
    JReturns.clear();

    while (!Worklist.empty()) {
      auto *BB = Worklist.pop_back_val();

      // Prevent loops
      if (!SeenBBs.insert(BB).second) {
        continue;
      }

      // Save the basic block
      const auto &BBLabel = getBBLabel(BB);
      const auto &[SrcStart, SrcEnd] = getSourceRange(BB);

      Json::Value JBlock;
      JBlock["start_line"] = SrcStart ? SrcStart.getLine() : Json::Value();
      JBlock["end_line"] = SrcEnd ? SrcEnd.getLine() : Json::Value();
      JBlocks[BBLabel] = JBlock;

      // Save the intra-procedural edges
      for (auto SI = succ_begin(BB), SE = succ_end(BB); SI != SE; ++SI) {
        Json::Value JEdge;
        JEdge["src"] = BBLabel;
        JEdge["dst"] = getBBLabel(*SI);
        JEdge["type"] = BB->getTerminator()->getOpcodeName();
        JEdges.append(JEdge);

        Worklist.push_back(*SI);
      }

      // Save the inter-procedural edges
      for (auto &I : *BB) {
        // Skip debug instructions
        if (isa<DbgInfoIntrinsic>(&I)) {
          continue;
        }

        if (const auto *CB = dyn_cast<CallBase>(&I)) {
          if (CB->isIndirectCall()) {
            JUnresolvedCalls.append(BBLabel);
          } else {
            const auto *Target =
                getCalledFunctionThroughAliasesAndCasts(CB->getCalledOperand());

            Json::Value JCall;
            JCall["src"] = BBLabel;
            JCall["dst"] = [&Target]() {
              if (const auto *IAsm = dyn_cast<InlineAsm>(Target)) {
                return IAsm->getAsmString();
              } else {
                return getNameOrAsOperand(Target);
              }
            }();
            JCall["type"] = I.getOpcodeName();

            JCalls.append(JCall);
          }
        }
      }

      const auto *Term = BB->getTerminator();
      assert(!isa<CatchSwitchInst>(Term) &&
             "catchswitch instruction not yet supported");
      assert(!isa<CatchReturnInst>(Term) &&
             "catchret instruction not yet supported");
      assert(!isa<CleanupReturnInst>(Term) &&
             "cleanupret instruction not yet supported");
      if (isa<ReturnInst>(Term) || isa<ResumeInst>(Term)) {
        Json::Value JReturn;
        JReturn["block"] = BBLabel;
        JReturn["type"] = Term->getOpcodeName();

        JReturns.append(JReturn);
      }
    }

    // Save function
    Json::Value JFunc;
    JFunc["name"] = getNameOrAsOperand(&F);
    JFunc["entry"] = getBBLabel(&F.getEntryBlock());
    JFunc["blocks"] = JBlocks;
    JFunc["edges"] = JEdges;
    JFunc["calls"] = JCalls;
    JFunc["returns"] = JReturns;
    JFunc["unresolved_calls"] = JUnresolvedCalls;
    JFuncs.append(JFunc);
  }

  // Print the results
  Json::Value JMod;
  JMod["module"] = M.getName().str();
  JMod["functions"] = JFuncs;

  const auto ModName = sys::path::filename(M.getName());
  SmallString<32> Filename(OutDir.c_str());
  sys::path::append(Filename, "cfg." + ModName + ".json");
  errs() << "Writing module '" << M.getName() << "' to '" << Filename << "'...";

  std::error_code EC;
  raw_fd_ostream File(Filename, EC, sys::fs::OF_Text);

  if (!EC) {
    File << JMod.toStyledString();
  } else {
    errs() << "  error opening file for writing!";
  }
  errs() << "\n";

  return false;
}
} // namespace

char MyCFGPass::ID = 1;

RegisterPass<MyCFGPass> X1("cfg2json", "CFG Pass",
                           false /* Only looks at CFG */,
                           false /* Analysis Pass */);

static RegisterStandardPasses Y1(PassManagerBuilder::EP_EarlyAsPossible,
                                 [](const PassManagerBuilder &Builder,
                                    legacy::PassManagerBase &PM) {
                                   PM.add(new MyCFGPass());
                                 });

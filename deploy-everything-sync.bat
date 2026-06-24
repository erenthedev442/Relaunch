@echo off
setlocal
title Legendary - Deploy Everything (+ Dev Sync)

REM ============================================================
REM  Legendary - Deploy Everything + DEV SYNC
REM  (a WRAPPER around deploy-everything.bat -- that file is NOT modified)
REM
REM  WHY:  the plain deploy only ever PUSHES, never pulls. So a collaborator's
REM        (shigukahz) commits to fjb/Legendary never reach the Azure box, and
REM        your push gets rejected once your laptop falls behind. This wrapper
REM        merges their work into your tree FIRST, then runs your normal deploy.
REM
REM  CONFLICT POLICY:  line-level + review list.
REM    * edits to different parts of the same file are auto-combined (nothing lost)
REM    * STOPS only when you both edited the SAME lines -> resolve, then re-run
REM    * always prints every file you both touched, so you can spot-check
REM
REM  SEQUENCE:
REM    [SYNC]  tools\dev_sync.py : commit local -> fetch fjb/Legendary ->
REM            review-list -> line-level merge (conflict flag aborts the run)
REM      then  call deploy-everything.bat   (your existing [0]..[6], unchanged)
REM ============================================================

set "SRC=D:\server"

echo(
echo   DEPLOY EVERYTHING  (+ DEV SYNC)
echo     1. Merge the collaborator's GitHub work into your tree (with a conflict flag)
echo     2. Run your normal deploy-everything.bat
echo(

echo  [SYNC] Pulling + merging the collaborator's work (fjb/Legendary)...
python "%SRC%\tools\dev_sync.py" "%SRC%" Legendary
if errorlevel 1 goto :syncfail

echo(
echo  [SYNC] OK -- collaborator's work is merged. Handing off to the full deploy...
echo(
call "%SRC%\deploy-everything.bat"
goto :done

:syncfail
echo(
echo   ============================================================
echo    DEPLOY ABORTED at the SYNC step (see the flag above).
echo    Nothing was shipped. Resolve the flagged file(s) -- yours /
echo    theirs / combine -- commit, then re-run this script.
echo   ============================================================
echo(
pause

:done
endlocal

@echo off

rem BatchRuntime-local compatibility path for BatchTest.
rem The standalone implementation lives in Engine\BatchTest.

call "%~dp0..\BatchTest\BatchTest.bat" %*
exit /b %errorlevel%

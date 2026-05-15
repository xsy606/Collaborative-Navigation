function results = main_run_smoke_tests()
%MAIN_RUN_SMOKE_TESTS Run lightweight checks for the static project.

results = run_smoke_tests();

if ~results.passed
    error('Static smoke tests failed.');
end

end

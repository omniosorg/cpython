
python$target:::function-entry
/copyinstr(arg1)=="test_unicode_stack"/
{
    self->trace = 1;
}
python$target:::function-entry
/self->trace/
{
    printf("[x]");
    jstack();
}
python$target:::function-return
/copyinstr(arg1)=="test_unicode_stack"/
{
    self->trace = 0;
}


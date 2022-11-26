
def function_1():
    pass

def function_2():
    function_1()

def function_3(dummy, dummy2):
    pass

def function_4(**dummy):
    pass

def function_5(dummy, dummy2, **dummy3):
    pass

def test_stack():
    function_1()
    function_2()
    function_3(*(1,2))
    function_4(**{"test":42})
    function_5(*(1,2), **{"test":42})

test_stack()


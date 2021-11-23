
def function_1():
    pass

def function_2():
    function_1()

def test_unicode_stack():
    def únícódé():
        function_2()
    function_1()
    únícódé()

test_unicode_stack()


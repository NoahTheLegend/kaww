string[] generateSolutions(int result, u8 difficulty)
{
	string[] solutions;

	for (u8 i = 0; i < quiz_options - 1; i++)
	{
		int solution = result + XORRandom(20) - 10;
		while (solution == result || solutions.find("" + solution) != -1)
		{
			solution = result + XORRandom(20) - 10;
		}
		solutions.push_back("" + solution);
	}

	solutions.insertAt(XORRandom(solutions.size()), "" + result);

	return solutions;
}

int getRandomFactor(int number) // doesnt return correct numbers
{
	array<int> factors;
	for (int i = 1; i <= number; i++)
	{
		if (number % i == 0)
		{
			factors.push_back(i);
		}
	}
	return factors[XORRandom(factors.size())];
}

int evaluateExpression(array<int> &numbers, array<string> &ops)
{
	array<int> numStack;
	array<string> opStack;

	for (u8 i = 0; i < numbers.size(); i++)
	{
		numStack.push_back(numbers[i]);

		if (i < ops.size())
		{
			string currentOp = ops[i];

			while (!opStack.isEmpty() && precedence(opStack[opStack.size() - 1]) >= precedence(currentOp))
			{
				int b = numStack[numStack.size() - 1]; numStack.removeAt(numStack.size() - 1);
				int a = numStack[numStack.size() - 1]; numStack.removeAt(numStack.size() - 1);
				string op = opStack[opStack.size() - 1]; opStack.removeAt(opStack.size() - 1);
				numStack.push_back(applyOperation(a, b, op));
			}

			opStack.push_back(currentOp);
		}
	}

	while (!opStack.isEmpty())
	{
		int b = numStack[numStack.size() - 1]; numStack.removeAt(numStack.size() - 1);
		int a = numStack[numStack.size() - 1]; numStack.removeAt(numStack.size() - 1);
		string op = opStack[opStack.size() - 1]; opStack.removeAt(opStack.size() - 1);
		numStack.push_back(applyOperation(a, b, op));
	}

	return numStack[0];
}

int precedence(string op)
{
	if (op == "*" || op == "/") return 2;
	if (op == "+" || op == "-") return 1;
	return 0;
}

int applyOperation(int a, int b, string op)
{
	if (op == "+") return a + b;
	if (op == "-") return a - b;
	if (op == "*") return a * b;
	if (op == "/") return a / b;
	return 0;
}

void setNewQuiz(CBlob@ this)
{
	u8 difficulty = XORRandom(3);
	string new_condition = generateQuiz(this, difficulty);

	this.set_string("quiz", new_condition);
	this.set_s32("quiz_change", getGameTime() + default_quiz_time);
}
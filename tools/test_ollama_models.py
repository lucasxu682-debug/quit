#!/usr/bin/env python3
"""
Ollama Model Tester
Test multiple models with same questions and compare results
"""

import subprocess
import time
import json
from pathlib import Path

OLLAMA_PATH = r"C:\Users\xumou\AppData\Local\Programs\Ollama\ollama.exe"

# Test questions covering different capabilities
TEST_QUESTIONS = [
    {
        "category": "general",
        "question": "What is RAG (Retrieval-Augmented Generation) in simple terms?",
        "expected": "Clear explanation of RAG concept"
    },
    {
        "category": "coding",
        "question": "Write a Python function to implement quicksort algorithm",
        "expected": "Correct, runnable Python code"
    },
    {
        "category": "chinese",
        "question": "请用中文解释什么是机器学习",
        "expected": "流利的中文解释"
    },
    {
        "category": "translation",
        "question": "Translate to English: '人工智能正在改变我们的生活方式'",
        "expected": "Accurate English translation"
    },
    {
        "category": "math",
        "question": "What is the sum of numbers from 1 to 100?",
        "expected": "5050 (or correct calculation)"
    }
]

def test_model(model_name, questions):
    """Test a single model"""
    print(f"\n{'='*60}")
    print(f"Testing Model: {model_name}")
    print(f"{'='*60}\n")
    
    results = {
        "model": model_name,
        "tests": [],
        "total_time": 0
    }
    
    for i, test in enumerate(questions, 1):
        print(f"\nTest {i}/{len(questions)}: {test['category'].upper()}")
        print(f"Q: {test['question']}")
        print("-" * 40)
        
        start_time = time.time()
        
        try:
            # Run model with question
            result = subprocess.run(
                [OLLAMA_PATH, "run", model_name],
                input=test['question'],
                capture_output=True,
                text=True,
                encoding='utf-8',
                timeout=60
            )
            
            elapsed = time.time() - start_time
            response = result.stdout.strip()
            
            # Truncate long responses
            if len(response) > 500:
                response = response[:500] + "... [truncated]"
            
            print(f"A: {response}")
            print(f"Time: {elapsed:.2f}s")
            
            results["tests"].append({
                "category": test['category'],
                "question": test['question'],
                "response": response,
                "time": elapsed,
                "success": result.returncode == 0
            })
            results["total_time"] += elapsed
            
        except subprocess.TimeoutExpired:
            print("[TIMEOUT] Model took too long to respond")
            results["tests"].append({
                "category": test['category'],
                "success": False,
                "error": "timeout"
            })
        except Exception as e:
            print(f"[ERROR] {e}")
            results["tests"].append({
                "category": test['category'],
                "success": False,
                "error": str(e)
            })
    
    return results

def generate_report(all_results):
    """Generate comparison report"""
    print("\n" + "="*60)
    print("MODEL COMPARISON REPORT")
    print("="*60)
    
    for result in all_results:
        model = result['model']
        tests = result['tests']
        total_time = result['total_time']
        
        print(f"\n[MODEL] {model}")
        print(f"   Total time: {total_time:.2f}s")
        print(f"   Avg time: {total_time/len(tests):.2f}s per test")
        
        for test in tests:
            status = "✓" if test.get('success') else "✗"
            cat = test['category']
            t = test.get('time', 0)
            print(f"   {status} {cat}: {t:.2f}s")
    
    # Save detailed report
    report_path = Path("ollama_test_report.json")
    report_path.write_text(json.dumps(all_results, indent=2, ensure_ascii=False), encoding='utf-8')
    print(f"\n📄 Detailed report saved: {report_path}")

def main():
    models = ["phi3:mini", "llama3.2:1b"]
    all_results = []
    
    print("[START] Starting Ollama Model Tests")
    print(f"Models to test: {', '.join(models)}")
    print(f"Test questions: {len(TEST_QUESTIONS)}")
    
    for model in models:
        results = test_model(model, TEST_QUESTIONS)
        all_results.append(results)
        time.sleep(2)  # Brief pause between models
    
    generate_report(all_results)
    
    print("\n[DONE] All tests completed!")

if __name__ == "__main__":
    main()

import os
import json
import subprocess
import time

def run_sql(query, fetch=False):
    cmd = [
        'docker', 'exec', '-i', 'analytics_db', 'psql', 
        '-U', 'postgres', '-d', 'analytics_db',
        '-q', '-t', '-A', '-P', 'pager=off'
    ]
    result = subprocess.run(cmd, input=query, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error running query: {result.stderr}")
        return None
    return result.stdout.strip()

def run_explain(query_file):
    with open(f"queries/{query_file}", 'r') as f:
        query = f.read()
    explain_query = f"EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) {query}"
    res = run_sql(explain_query)
    try:
        plan = json.loads(res)
        return plan[0]['Execution Time'], plan
    except Exception as e:
        print(f"Error parsing explain for {query_file}: {e}")
        return 0, None

def run_pgbench(query_file, time_s=60):
    subprocess.run(['docker', 'cp', f"queries/{query_file}", f"analytics_db:/{query_file}"])
    cmd = [
        'docker', 'exec', 'analytics_db', 'pgbench',
        '-U', 'postgres', '-d', 'analytics_db',
        '-f', f"/{query_file}",
        '-c', '10', '-j', '2', '-T', str(time_s)
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    out = result.stdout
    tps = 0
    for line in out.split('\n'):
        if line.startswith('tps = ') and '(without initial connection time)' in line:
            tps = float(line.split('tps = ')[1].split(' ')[0])
            break
    return tps

def main():
    os.makedirs('benchmarks', exist_ok=True)
    os.makedirs('results', exist_ok=True)
    
    results = {}
    
    for i in range(1, 6):
        print(f"Benchmarking Query {i}...")
        wf_ms, wf_plan = run_explain(f"window_q{i}.sql")
        cte_ms, cte_plan = run_explain(f"cte_q{i}.sql")
        
        if wf_plan:
            with open(f"benchmarks/q{i}_window_plan.json", "w") as f:
                json.dump(wf_plan, f, indent=2)
        if cte_plan:
            with open(f"benchmarks/q{i}_cte_plan.json", "w") as f:
                json.dump(cte_plan, f, indent=2)
            
        results[f"query_{i}"] = {
            "wf_ms": round(wf_ms, 2),
            "cte_ms": round(cte_ms, 2),
            "index_speedup": 1.0
        }

    # Apply Indexes
    print("Applying indexes...")
    run_sql("CREATE INDEX idx_orders_user_created ON orders(user_id, created_at);")
    run_sql("CREATE INDEX idx_users_cohort ON users(cohort_month);")
    run_sql("VACUUM ANALYZE orders;")
    run_sql("VACUUM ANALYZE users;")

    print("Re-benchmarking Query 1 and Query 2 for speedup...")
    wf_ms_idx, wf_plan_idx = run_explain("window_q1.sql")
    if wf_ms_idx > 0 and results["query_1"]["wf_ms"] > 0:
        speedup = results["query_1"]["wf_ms"] / wf_ms_idx
        results["query_1"]["index_speedup"] = round(speedup, 2)
        if wf_plan_idx:
            with open(f"benchmarks/q1_window_plan_indexed.json", "w") as f:
                json.dump(wf_plan_idx, f, indent=2)

    wf_q2_ms_idx, _ = run_explain("window_q2.sql")
    if wf_q2_ms_idx > 0 and results["query_2"]["wf_ms"] > 0:
        q2_speedup = results["query_2"]["wf_ms"] / wf_q2_ms_idx
        results["query_2"]["index_speedup"] = round(q2_speedup, 2)

    print("Running pgbench for Query 1...")
    q1_wf_tps = run_pgbench("window_q1.sql", time_s=60)
    q1_cte_tps = run_pgbench("cte_q1.sql", time_s=60)
    
    results["pgbench_results"] = {
        "wf_tps": q1_wf_tps,
        "cte_tps": q1_cte_tps
    }

    # Materialized View Benchmarking
    print("Benchmarking Materialized View...")
    start = time.time()
    run_sql(open("queries/mv_q1.sql").read())
    mv_create_ms = (time.time() - start) * 1000

    run_sql("INSERT INTO orders (user_id, product_id, amount, status, created_at) SELECT floor(random()*100000)+1, 1, 50, 'completed', NOW() FROM generate_series(1, 10000);")
    
    start = time.time()
    run_sql("REFRESH MATERIALIZED VIEW daily_revenue_stats;")
    mv_refresh_ms = (time.time() - start) * 1000

    res = run_sql("EXPLAIN (ANALYZE, FORMAT JSON) SELECT * FROM daily_revenue_stats;")
    try:
        mv_plan = json.loads(res)
        mv_read_time = mv_plan[0]['Execution Time']
    except Exception as e:
        print(f"Error reading MV plan: {e}")
        mv_read_time = 0

    results["materialized_view"] = {
        "creation_ms": round(mv_create_ms, 2),
        "refresh_ms": round(mv_refresh_ms, 2),
        "read_ms": round(mv_read_time, 2)
    }

    with open("results/benchmarks.json", "w") as f:
        json.dump(results, f, indent=2)
        
    with open("results.json", "w") as f:
        json.dump(results, f, indent=2)

    print("Benchmarking completed.")

if __name__ == "__main__":
    main()

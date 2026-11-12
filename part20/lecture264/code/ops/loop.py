"""監視を決まった間隔で回し続ける。周回ごとに終了コードとかかった時間を一行ずつ書く。Python標準ライブラリだけ。

  python -I ops/loop.py <間隔 秒> <周回数、0なら無限> <記録ファイル> -- <monitor.pyの引数そのまま>
- 一周が例外で落ちても次の周を回す(落ちた周は記録に"失敗"として残る)
- このプログラム自身が止まると、監視の状態ファイルの最後の周回時刻が止まる。それは別の機械から
  monitor.py --heartbeatが見る(同じ機械で見ると一緒に止まる)
"""
import os
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))


def main(argv):
    every, rounds, log = float(argv[0]), int(argv[1]), argv[2]
    args = argv[argv.index('--') + 1:]
    i = 0
    while rounds == 0 or i < rounds:
        t0 = time.time()
        r = subprocess.run([sys.executable, '-I', '-X', 'utf8', os.path.join(HERE, 'monitor.py'), *args],
                           capture_output=True, text=True, encoding='utf-8')
        took = time.time() - t0
        first = (r.stdout.splitlines() or [''])[0]
        state = {0: '異常なし', 1: '開いている警報'}.get(r.returncode, '失敗 %d' % r.returncode)
        with open(log, 'a', encoding='utf-8') as f:
            f.write('%s | %s | %.1f秒 | %s\n' % (time.strftime('%H:%M:%S'), state, took, first))
            if r.returncode not in (0, 1):
                f.write('  ' + (r.stderr.strip().splitlines() or [''])[-1] + '\n')
        i += 1
        time.sleep(max(0.0, every - took))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

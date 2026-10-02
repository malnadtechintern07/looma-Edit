    </main>
    <footer class="mt-auto py-3 px-4 border-top bg-white text-muted small text-center">
        <div>
            &copy; <?= date('Y') ?> <strong class="text-dark"><?= htmlspecialchars(APP_NAME) ?></strong>. All rights reserved.
        </div>
    </footer>
</div>
</div>

<script>
    function toggleSidebar() {
        const sb = document.getElementById('sidebar');
        if (sb) sb.classList.toggle('show');
    }

    // Ensure profile dropdown toggling works smoothly in all scenarios
    document.addEventListener('DOMContentLoaded', function () {
        const toggles = document.querySelectorAll('[data-bs-toggle="dropdown"]');
        toggles.forEach(function (btn) {
            btn.addEventListener('click', function (e) {
                const parent = this.closest('.dropdown');
                if (!parent) return;
                const menu = parent.querySelector('.dropdown-menu');
                if (!menu) return;

                setTimeout(function () {
                    if (!menu.classList.contains('show')) {
                        menu.classList.add('show');
                        btn.setAttribute('aria-expanded', 'true');
                    }
                }, 50);
            });
        });

        // Close dropdown when clicked outside
        document.addEventListener('click', function (e) {
            if (!e.target.closest('.dropdown')) {
                document.querySelectorAll('.dropdown-menu.show').forEach(function (menu) {
                    menu.classList.remove('show');
                    const btn = menu.closest('.dropdown')?.querySelector('[data-bs-toggle="dropdown"]');
                    if (btn) btn.setAttribute('aria-expanded', 'false');
                });
            }
        });
    });
</script>
</body>
</html>

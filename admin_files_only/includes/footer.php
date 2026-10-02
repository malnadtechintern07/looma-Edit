    </main>
    <footer class="mt-auto py-3 px-4 border-top bg-white text-muted small text-center">
        <div>
            &copy; <?= date('Y') ?> <strong class="text-dark"><?= htmlspecialchars(APP_NAME) ?></strong>. All rights reserved.
        </div>
    </footer>
</div>
</div>

<!-- Bootstrap 5.3 JS Bundle -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
    function toggleSidebar() {
        const sb = document.getElementById('sidebar');
        if (sb) sb.classList.toggle('show');
    }
</script>
</body>
</html>

import asyncio
from playwright.async_api import async_playwright

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(
            user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36',
            viewport={'width': 1707, 'height': 1067}
        )
        
        # Add cookies
        cookies = [
            {'name': 's_v_web_id', 'value': 'verify_mmmg8cxh_0VuZw8Db_B5JI_4YoD_9Mcg_uRIogKbBVPrZ', 'domain': '.douyin.com', 'path': '/'},
            {'name': 'passport_csrf_token', 'value': '68e1fffc54425bb379bd8aab3b551ee1', 'domain': '.douyin.com', 'path': '/'},
            {'name': 'login_time', 'value': '1775192233883', 'domain': '.douyin.com', 'path': '/'},
            {'name': 'IsDouyinActive', 'value': 'true', 'domain': '.douyin.com', 'path': '/'},
        ]
        await context.add_cookies(cookies)
        
        page = await context.new_page()
        
        print('Navigating to video...')
        await page.goto('https://www.douyin.com/video/7623877586552147251', timeout=30000)
        await page.wait_for_timeout(5000)
        
        # Try to get data via JavaScript
        result = await page.evaluate('''() => {
            // Try to find video info in window
            const keys = Object.keys(window).filter(k => k.includes('STATE') || k.includes('state') || k.includes('data') || k.includes('Data'));
            return {
                keys: keys.slice(0, 10),
                title: document.title,
                bodyText: document.body.innerText.slice(0, 500)
            };
        }''')
        
        print('Window keys:', result['keys'])
        print('Title:', result['title'])
        print('Body text:', result['bodyText'])
        
        await browser.close()

asyncio.run(main())
